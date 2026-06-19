const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL || 'https://llkckimmpvbnehrzapsr.supabase.co';
// Use the anon key to trigger reset password like the client app does
const supabaseKey = process.env.SUPABASE_ANON_KEY;

if (!supabaseKey) {
  console.error('Error: SUPABASE_ANON_KEY is not defined in .env');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function testReset() {
  const email = 'sohammisal22@gmail.com';
  console.log(`Sending reset password email to: ${email}...`);
  
  const { data, error } = await supabase.auth.resetPasswordForEmail(email, {
    redirectTo: 'ilikeit://reset-password',
  });

  if (error) {
    console.error('Error returned by Supabase:');
    console.error(JSON.stringify(error, null, 2));
  } else {
    console.log('Success!', data);
  }
}

testReset();
