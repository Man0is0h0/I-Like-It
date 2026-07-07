# Upload the fixed transparent-corners logo to Production Supabase Storage
# You need your Service Role Key for this (find it in Supabase Dashboard > Settings > API)

param(
    [Parameter(Mandatory=$true)]
    [string]$ServiceRoleKey
)

$supabaseUrl = "https://baelekmfmvlyglowofab.supabase.co"
$logoPath = Join-Path $PSScriptRoot "App_icon_final.png"

if (-not (Test-Path $logoPath)) {
    Write-Host "ERROR: Logo file not found at $logoPath" -ForegroundColor Red
    exit 1
}

Write-Host "Uploading fixed logo (transparent corners) to production..." -ForegroundColor Cyan

$fileBytes = [System.IO.File]::ReadAllBytes($logoPath)

# Try PUT first (update existing)
try {
    $response = Invoke-RestMethod -Uri "$supabaseUrl/storage/v1/object/assets/logo.png" `
        -Method PUT `
        -Headers @{
            "Authorization" = "Bearer $ServiceRoleKey"
            "apikey" = $ServiceRoleKey
            "Content-Type" = "image/png"
            "Cache-Control" = "no-cache"
        } `
        -Body $fileBytes
    Write-Host "SUCCESS: Logo updated!" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Gray
} catch {
    Write-Host "PUT failed, trying POST with x-upsert..." -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri "$supabaseUrl/storage/v1/object/assets/logo.png" `
            -Method POST `
            -Headers @{
                "Authorization" = "Bearer $ServiceRoleKey"
                "apikey" = $ServiceRoleKey
                "Content-Type" = "image/png"
                "x-upsert" = "true"
                "Cache-Control" = "no-cache"
            } `
            -Body $fileBytes
        Write-Host "SUCCESS: Logo uploaded!" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Upload failed: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $errorBody = $reader.ReadToEnd()
            Write-Host "Error body: $errorBody" -ForegroundColor Red
        }
    }
}

$publicUrl = "$supabaseUrl/storage/v1/object/public/assets/logo.png"
Write-Host "`n=== PUBLIC LOGO URL ===" -ForegroundColor Cyan
Write-Host $publicUrl
Write-Host "========================"
