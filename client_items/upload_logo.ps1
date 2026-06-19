# Upload logo to Supabase Storage
# This script uploads the app logo to a public bucket so it can be used in email templates

$supabaseUrl = "https://llkckimmpvbnehrzapsr.supabase.co"
$supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxsa2NraW1tcHZibmVocnphcHNyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcwOTQ0MzcsImV4cCI6MjA5MjY3MDQzN30.1HIA0_D286l7n_ITosGh6vrs3dyX0px958Eopl5MBM4"

$logoPath = "c:\Users\misal\OneDrive\Documents\I like it\I-Like-It\client_items\App iconn.png"

# Step 1: Create the bucket (ignore error if already exists)
Write-Host "Creating 'assets' bucket..."
$bucketBody = @{
    id = "assets"
    name = "assets"
    public = $true
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$supabaseUrl/storage/v1/bucket" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $supabaseKey"
            "apikey" = $supabaseKey
            "Content-Type" = "application/json"
        } `
        -Body $bucketBody
    Write-Host "Bucket created: $($response | ConvertTo-Json)"
} catch {
    Write-Host "Bucket may already exist (this is OK): $($_.Exception.Message)"
}

# Step 2: Upload the logo file
Write-Host "`nUploading logo..."
$fileBytes = [System.IO.File]::ReadAllBytes($logoPath)

try {
    $response = Invoke-RestMethod -Uri "$supabaseUrl/storage/v1/object/assets/logo.png" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $supabaseKey"
            "apikey" = $supabaseKey
            "Content-Type" = "image/png"
            "x-upsert" = "true"
        } `
        -Body $fileBytes
    Write-Host "Upload response: $($response | ConvertTo-Json)"
} catch {
    Write-Host "Upload error: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $errorBody = $reader.ReadToEnd()
        Write-Host "Error body: $errorBody"
    }
}

# Step 3: Print the public URL
$publicUrl = "$supabaseUrl/storage/v1/object/public/assets/logo.png"
Write-Host "`n=== PUBLIC LOGO URL ==="
Write-Host $publicUrl
Write-Host "========================"
Write-Host "`nUse this URL in your email templates!"
