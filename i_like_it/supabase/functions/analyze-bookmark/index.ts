

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const geminiApiKey = Deno.env.get('GEMINI_API_KEY')
    if (!geminiApiKey) {
      throw new Error('GEMINI_API_KEY is not set')
    }

    const { title, description, content, existingFolders } = await req.json()

    const existingFoldersText =
      existingFolders && existingFolders.length > 0
        ? 'Existing Folders to choose from:\n- ' + existingFolders.join('\n- ')
        : 'No existing folders.';

    const pageContent = content && content.length > 500 ? content.substring(0, 500) : (content || "None");

    const prompt = `Based on this content information, suggest 3 concise NEW folder names that would organize this content well, AND pick the 1 BEST matching existing folder if any (or none).

Content Information:
Title: ${title || "None"}
Description: ${description || "None"}
Page Content/Keywords: ${pageContent}

${existingFoldersText}

Format your response exactly like this:
NEW: Folder Name 1
NEW: Folder Name 2
NEW: Folder Name 3
EXISTING: [Best matching existing folder name, or "None"]`;

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${geminiApiKey}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          contents: [
            {
              parts: [{ text: prompt }],
            },
          ],
        }),
      }
    );

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Gemini API error: ${response.status} - ${errorText}`);
    }

    const data = await response.json();
    const text = data.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!text) {
      throw new Error('No text returned from Gemini API');
    }

    const newFolders: string[] = [];
    let bestExistingFolder: string | null = null;

    const lines = text.split('\n');
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed) continue;

      const newMatch = trimmed.match(/^\*?\*?NEW:\*?\*?\s*(.*)/i);
      const existingMatch = trimmed.match(/^\*?\*?EXISTING:\*?\*?\s*(.*)/i);

      if (newMatch) {
        let suggestion = newMatch[1].trim();
        suggestion = suggestion.replace(/^["\d+"\-*)\\]\s]*/, '').trim();
        if (suggestion.startsWith('"') || suggestion.startsWith("'")) {
          suggestion = suggestion.substring(1);
        }
        if (suggestion.endsWith('"') || suggestion.endsWith("'")) {
          suggestion = suggestion.substring(0, suggestion.length - 1);
        }
        if (suggestion && suggestion.length < 50) {
          newFolders.push(suggestion);
        }
      } else if (existingMatch) {
        const existing = existingMatch[1].trim();
        if (existing.toLowerCase() !== 'none' && existing) {
          bestExistingFolder = existing;
        }
      }
    }

    return new Response(
      JSON.stringify({
        newFolders: newFolders.slice(0, 3),
        bestExistingFolder,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error)
    return new Response(JSON.stringify({ error: errorMessage }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
