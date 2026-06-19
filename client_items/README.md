# 📂 Client Items Folder

Please place the requested client credentials and assets in this folder. Here is the list of files to add:

### 1. `smtp_details.txt`
Create a text file containing the Zoho SMTP credentials in the following format:
```text
SMTP_HOST=smtp.zoho.in
SMTP_PORT=465
SMTP_USER=support@ilikeit.co.in
SMTP_PASS=your_zoho_smtp_password
```

### 2. `urls.txt`
Create a text file containing the legal URLs:
```text
PRIVACY_POLICY_URL=https://your-domain.com/privacy-policy
TERMS_OF_USE_URL=https://your-domain.com/terms-of-use
```

### 3. `verification_email.html`
Place the custom HTML template for the email verification/OTP message here.

### 4. `reset_password_email.html`
Place the custom HTML template for the password reset email here.

### 5. `welcome_email.html`
Place the custom HTML template for the welcome email here.

### 6. `logo.png`
Place the official brand logo image here. We will upload this to Supabase Storage during the implementation to get a permanent public URL.
