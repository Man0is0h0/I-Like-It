// @ts-nocheck
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
      throw new Error("Missing environment configuration: SUPABASE_URL or SUPABASE_ANON_KEY");
    }

    const url = new URL(req.url);
    const page = url.searchParams.get('page')?.toLowerCase();

    let fileName = '';
    if (page === 'privacy') {
      fileName = 'Privacy_Policy_iLikeIt.html';
    } else if (page === 'terms') {
      fileName = 'Terms_Use_iLikeIt.html';
    } else {
      return new Response(
        `<html>
          <head>
            <title>Invalid Page</title>
            <style>
              body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; text-align: center; padding: 50px; background-color: #f4f7fb; color: #333; }
              .card { background: white; max-width: 500px; margin: 0 auto; padding: 30px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
              code { background: #eee; padding: 2px 6px; border-radius: 4px; font-family: monospace; }
            </style>
          </head>
          <body>
            <div class="card">
              <h1>Invalid Page Requested</h1>
              <p>Please specify a valid legal page query parameter, e.g., <code>?page=privacy</code> or <code>?page=terms</code></p>
            </div>
          </body>
        </html>`, 
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'text/html; charset=utf-8' } 
        }
      );
    }

    // Initialize Supabase Client with Anon Key
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

    // Download the file from storage
    const { data, error } = await supabase.storage
      .from('legal-docs')
      .download(fileName);

    if (error || !data) {
      console.error(`Error downloading ${fileName}:`, error);
      return new Response(
        `<html>
          <head>
            <title>File Not Found</title>
            <style>
              body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; text-align: center; padding: 50px; background-color: #f4f7fb; color: #333; }
              .card { background: white; max-width: 500px; margin: 0 auto; padding: 30px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
            </style>
          </head>
          <body>
            <div class="card">
              <h1>Document Not Found</h1>
              <p>The requested legal document could not be retrieved from storage. Please verify that the file exists in your bucket.</p>
            </div>
          </body>
        </html>`, 
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'text/html; charset=utf-8' } 
        }
      );
    }

    // Read the text contents of the HTML file
    const htmlContent = await data.text();

    // Return the HTML response with the correct Content-Type header so the browser renders it!
    return new Response(htmlContent, {
      status: 200,
      headers: {
        ...corsHeaders,
        'Content-Type': 'text/html; charset=utf-8',
        'Cache-Control': 'public, max-age=3600', // Cache for 1 hour to reduce API hits
      }
    });

  } catch (error: any) {
    console.error("Function error:", error);
    return new Response(
      `<html>
        <head>
          <title>Server Error</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; text-align: center; padding: 50px; background-color: #f4f7fb; color: #333; }
            .card { background: white; max-width: 500px; margin: 0 auto; padding: 30px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
          </style>
        </head>
        <body>
          <div class="card">
            <h1>Server Error</h1>
            <p>An error occurred: <code>${error.message}</code></p>
          </div>
        </body>
      </html>`, 
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'text/html; charset=utf-8' } 
      }
    );
  }
})
