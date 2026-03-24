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

    // ----- METHOD 1: GMAIL SMTP -----
    if (GMAIL_PASSWORD) {
      console.log("Using Gmail SMTP via Nodemailer...");
      
      const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
          user: GMAIL_EMAIL,
          pass: GMAIL_PASSWORD,
        },
      });

      await transporter.sendMail({
        from: `"ILikeIt App" <${GMAIL_EMAIL}>`,
        to: email,
        subject: "Your Login Code",
        text: `Your verification code is: ${otp}`, // Fallback text
        html: htmlContent,
      });

      return new Response(JSON.stringify({ success: true, method: "gmail" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    // ----- METHOD 2: RESEND API -----
    if (RESEND_API_KEY) {
      console.log("Using Resend API...");
      const res = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${RESEND_API_KEY}`,
        },
        body: JSON.stringify({
          from: 'ILikeIt App <onboarding@resend.dev>', // UPDATE THIS if you have a custom domain
          to: [email],
          subject: 'Your Login Code',
          html: htmlContent,
        }),
      });

      const data = await res.json()

      if (!res.ok) {
          console.error("Resend Error:", data);
          throw new Error(`Failed to send email: ${JSON.stringify(data)}`);
      }

      return new Response(JSON.stringify(data), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    throw new Error("No Email service configured. Please provide GMAIL_PASSWORD or RESEND_API_KEY.");

  } catch (error: any) {
    console.error(error)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400, // Returning 400 instead of 500 matches your old code style
    })
  }
})
