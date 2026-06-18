// @ts-nocheck
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import nodemailer from "npm:nodemailer";

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')
const GMAIL_PASSWORD = Deno.env.get('GMAIL_PASSWORD')
const GMAIL_EMAIL = Deno.env.get('GMAIL_EMAIL') || 'manis2072004@gmail.com'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const payload = await req.json()
    
    const record = payload.record;
    
    if (!record || !record.email || !record.otp_code) {
      throw new Error("Invalid payload: Missing email or otp_code");
    }

    const email = record.email;
    const otp = record.otp_code;

    console.log(`Sending OTP to ${email}`);

    const htmlContent = `
      <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto;">
        <h2>Login Verification</h2>
        <p>Your verification code is:</p>
        <h1 style="color: #007bff; letter-spacing: 5px;">${otp}</h1>
        <p>This code will expire in 15 minutes.</p>
        <p style="font-size: 12px; color: #666;">If you didn't request this, ignore this email.</p>
      </div>
    `;

    // ----- ZOHO SMTP -----
    console.log("Using Zoho SMTP via Nodemailer...");
    
    const transporter = nodemailer.createTransport({
      host: 'smtp.zoho.in',
      port: 465,
      secure: true, // true for 465, false for other ports
      auth: {
        user: Deno.env.get('SMTP_USER') || 'support@ilikeit.co.in',
        pass: Deno.env.get('SMTP_PASS') || 'owner_srk@5781',
      },
    });

    await transporter.sendMail({
      from: `"iLikeIt Support" <support@ilikeit.co.in>`,
      to: email,
      subject: "Your Login Code",
      text: `Your verification code is: ${otp}`, // Fallback text
      html: htmlContent,
    });

    return new Response(JSON.stringify({ success: true, method: "zoho" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });

  } catch (error: any) {
    console.error(error)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400, // Returning 400 instead of 500 matches your old code style
    })
  }
})
