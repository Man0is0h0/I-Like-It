# Read .env file
$env = @{}
if (-not (Test-Path .env)) {
    Write-Host "Error: .env file not found in current directory." -ForegroundColor Red
    Exit 1
}

Get-Content .env | ForEach-Object {
    $line = $_.Trim()
    if ($line -match '^([^=]+)=(.*)$') {
        $env[$Matches[1]] = $Matches[2].Trim()
    }
}

$url = $env["SUPABASE_URL"]
$anon_key = $env["SUPABASE_ANON_KEY"]

if (-not $url -or -not $anon_key) {
    Write-Host "Error: SUPABASE_URL or SUPABASE_ANON_KEY not found in .env" -ForegroundColor Red
    Exit 1
}

# Remove trailing slash if present
if ($url.EndsWith("/")) {
    $url = $url.Substring(0, $url.Length - 1)
}

# Paths to the HTML files
$privacyPath = "../client_items/Privacy_Policy_iLikeIt.html"
$termsPath = "../client_items/Terms_Use_iLikeIt.html"

# Function to upload file
function Upload-File ($filePath, $remoteName) {
    if (-not (Test-Path $filePath)) {
        Write-Host "Error: File $filePath not found" -ForegroundColor Red
        return
    }

    $uploadUrl = "$url/storage/v1/object/legal-docs/$remoteName"
    
    $headers = @{
        "apikey" = $anon_key
        "Authorization" = "Bearer $anon_key"
        "Content-Type" = "text/html"
        "x-upsert" = "true"
    }

    $fileBytes = [System.IO.File]::ReadAllBytes((Resolve-Path $filePath))

    Write-Host "Uploading $remoteName to $uploadUrl..."
    try {
        $response = Invoke-RestMethod -Uri $uploadUrl -Method Post -Headers $headers -Body $fileBytes
        Write-Host "Successfully uploaded $remoteName!" -ForegroundColor Green
    } catch {
        Write-Host "Failed to upload $remoteName. Error: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $errBody = $reader.ReadToEnd()
            Write-Host "Error Details: $errBody" -ForegroundColor Yellow
        }
    }
}

Upload-File $privacyPath "Privacy_Policy_iLikeIt.html"
Upload-File $termsPath "Terms_Use_iLikeIt.html"

$privacyPublicUrl = "$url/storage/v1/object/public/legal-docs/Privacy_Policy_iLikeIt.html"
$termsPublicUrl = "$url/storage/v1/object/public/legal-docs/Terms_Use_iLikeIt.html"

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host "🎉 UPLOAD COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Privacy Policy URL:"
Write-Host $privacyPublicUrl -ForegroundColor Yellow
Write-Host "`nTerms of Use URL:"
Write-Host $termsPublicUrl -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Cyan
