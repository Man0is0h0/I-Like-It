import { createClient } from "@supabase/supabase-js";

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};
    
const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY');
const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

// List of allowed categories (synced with Dart app)
const ALLOWED_CATEGORIES = [
    'coding', 'web_development', 'mobile_apps', 'ai_ml', 'data_science',
    'cloud_computing', 'hardware', 'cybersecurity', 'tech_news',
    'courses', 'university', 'research', 'books', 'career', 'certificates',
    'movies', 'series', 'anime', 'gaming', 'music', 'podcasts', 'youtube',
    'fitness', 'health', 'recipes', 'travel', 'fashion', 'home_decor',
    'investing', 'crypto', 'banking', 'business', 'real_estate',
    'news', 'social_media', 'shopping', 'personal', 'project', 'other'
];

Deno.serve(async (req: Request) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }

    try {
        if (!GEMINI_API_KEY) throw new Error('Missing GEMINI_API_KEY');
        if (!SUPABASE_URL) throw new Error('Missing SUPABASE_URL (or APP_SUPABASE_URL)');
        if (!SUPABASE_SERVICE_ROLE_KEY) throw new Error('Missing APP_SERVICE_ROLE_KEY');

        const authHeader = req.headers.get('Authorization');
        if (!authHeader || authHeader !== `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`) {
            return new Response(JSON.stringify({ error: "Unauthorized" }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
                status: 401,
            });
        }

        const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

        // 1. Fetch unclassified folders (Batch size 10 to avoid timeouts)
        const { data: folders, error: fetchError } = await supabase
            .from('folders')
            .select('id, name')
            .or('system_category.is.null,system_category.eq.other')
            .limit(10);

        if (fetchError) throw fetchError;
        if (!folders || folders.length === 0) {
            return new Response(JSON.stringify({ message: "No unclassified folders found." }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            });
        }

        console.log(`Processing ${folders.length} folders...`);
        const updates = [];

        // 2. Process each folder
        for (const folder of folders) {
            if (!folder.name) continue;

            // Rate limit delay (1s)
            await new Promise(resolve => setTimeout(resolve, 1000));

            const category = await classifyWithGemini(folder.name);

            if (category) {
                updates.push({
                    id: folder.id,
                    system_category: category,
                });
            }
        }

        // 3. Update each folder individually (to avoid upsert "not-null" constraint issues)
        if (updates.length > 0) {
            console.log(`Updating ${updates.length} folders in database...`);
            for (const update of updates) {
                const { error: updateError } = await supabase
                    .from('folders')
                    .update({ system_category: update.system_category })
                    .eq('id', update.id);

                if (updateError) {
                    console.error(`Failed to update folder ${update.id}:`, updateError);
                }
            }
        }

        return new Response(JSON.stringify({
            message: `Processed ${folders.length} folders. Updated ${updates.length}.`,
            updates
        }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
        });

    } catch (error) {
        console.error(error);
        return new Response(JSON.stringify({ error: (error as Error).message }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 500,
        });
    }
});

async function classifyWithGemini(folderName: string): Promise<string | null> {
    const models = [
        'gemini-2.5-flash',
        'gemini-2.0-flash',
        'gemini-flash-latest'
    ];

    const prompt = `
Classify the following folder name into exactly ONE of these categories:
${ALLOWED_CATEGORIES.join(', ')}.

Folder name: "${folderName}"

Respond with ONLY the category name. No explanation. No punctuation. Lowercase.
`;

    for (const model of models) {
        try {
            // console.log(`Trying model: ${model}...`);
            const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${GEMINI_API_KEY}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    contents: [
                        {
                            role: "user",
                            parts: [{ text: prompt }]
                        }
                    ]
                })

            });

            if (!response.ok) {
                if (response.status === 404) {
                    console.warn(`Model ${model} not found (404). Trying next...`);
                    continue;
                }
                const errorText = await response.text();
                console.error(`Gemini API Error (${model}): ${response.status} ${response.statusText}`, errorText);
                return null; // Don't retry other models for non-404 errors (like 400 Bad Request)
            }

            const data = await response.json();
            let text = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim().toLowerCase();

            if (!text) return null;

            // Clean up
            text = text.replace(/[^a-z_]/g, '');

            if (ALLOWED_CATEGORIES.includes(text)) {
                return text;
            }

            // Fuzzy matching
            for (const cat of ALLOWED_CATEGORIES) {
                if (text.includes(cat)) return cat;
            }

            return 'other';

        } catch (e) {
            console.error(`Gemini Fetch Error (${model}):`, e);
        }
    }

    // If all fail, try to list available models for debugging
    console.error("All Gemini models failed. Attempting to list available models...");
    await listAvailableModels();
    return null;
}

async function listAvailableModels() {
    try {
        const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models?key=${GEMINI_API_KEY}`);
        if (!response.ok) {
            console.error(`ListModels Failed: ${response.status} ${response.statusText}`, await response.text());
            return;
        }
        const data = await response.json();
        const modelNames = data.models?.map((m: { name: string }) => m.name) || [];
        console.log("AVAILABLE MODELS:", JSON.stringify(modelNames, null, 2));
    } catch (e) {
        console.error("ListModels Exception:", e);
    }
}
