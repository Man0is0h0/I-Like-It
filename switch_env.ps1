# PowerShell Environment Switcher for iLikeIt
param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "prod")]
    [string]$env
)

$targetDir = Join-Path $PSScriptRoot "i_like_it"
$targetEnvFile = Join-Path $targetDir ".env"

if ($env -eq "dev") {
    $sourceFile = Join-Path $targetDir ".env.development"
    if (Test-Path $sourceFile) {
        Copy-Item $sourceFile $targetEnvFile -Force
        Write-Host "SUCCESS: Switched to DEVELOPMENT environment." -ForegroundColor Green
        Write-Host "Active Supabase URL: $(Get-Content $targetEnvFile | Select-String "SUPABASE_URL=")" -ForegroundColor Cyan
    } else {
        Write-Error "Could not find $sourceFile"
    }
} elseif ($env -eq "prod") {
    $sourceFile = Join-Path $targetDir ".env.production"
    if (Test-Path $sourceFile) {
        Copy-Item $sourceFile $targetEnvFile -Force
        Write-Host "SUCCESS: Switched to PRODUCTION environment." -ForegroundColor Green
        Write-Host "Active Supabase URL: $(Get-Content $targetEnvFile | Select-String "SUPABASE_URL=")" -ForegroundColor Cyan
    } else {
        Write-Error "Could not find $sourceFile"
    }
}
