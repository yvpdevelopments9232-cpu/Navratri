# ==============================================================================
# Navratri Utsav - Download Latest iOS .IPA & macOS App from GitHub Actions
# ==============================================================================

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "   NAVRATRI UTSAV - GITHUB ACTIONS ARTIFACT DOWNLOADER" -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Cyan

# 1. Obtain GitHub Authentication Token from Git Credential Manager
Write-Host "`n[1/4] Retrieving GitHub authentication token..." -ForegroundColor White
$credText = ("protocol=https`nhost=github.com`n" | git credential fill) -split "`n"
$tokenLine = $credText | Where-Object { $_ -match "^password=" }
if (-not $tokenLine) {
    Write-Host "[ERROR] Could not retrieve GitHub credentials from Git Credential Manager." -ForegroundColor Red
    exit 1
}
$token = $tokenLine.Substring(9).Trim()
$headers = @{
    'Authorization' = "Bearer $token"
    'User-Agent'    = 'Navratri-Downloader'
}

# 2. Find the latest successful GitHub Actions run
Write-Host "[2/4] Querying latest successful GitHub Actions build..." -ForegroundColor White
$runsUrl = 'https://api.github.com/repos/yvpdevelopments9232-cpu/Navratri/actions/runs?status=success'
$runs = (Invoke-RestMethod -Uri $runsUrl -Headers $headers).workflow_runs
if (-not $runs -or $runs.Count -eq 0) {
    Write-Host "[ERROR] No completed successful GitHub Actions workflow runs found." -ForegroundColor Red
    exit 1
}

$latestRun = $runs[0]
Write-Host " -> Found Successful Run #$($latestRun.run_number) (ID: $($latestRun.id))" -ForegroundColor Green
Write-Host " -> Commit: $($latestRun.head_commit.message)" -ForegroundColor Gray
Write-Host " -> URL: $($latestRun.html_url)" -ForegroundColor Gray

# 3. Query artifacts for this run
Write-Host "`n[3/4] Finding iOS IPA and macOS build artifacts..." -ForegroundColor White
$artifactsUrl = "https://api.github.com/repos/yvpdevelopments9232-cpu/Navratri/actions/runs/$($latestRun.id)/artifacts"
$artifacts = (Invoke-RestMethod -Uri $artifactsUrl -Headers $headers).artifacts

$iosArtifact = $artifacts | Where-Object { $_.name -eq 'Navratri_Utsav_iOS_IPA' }
if (-not $iosArtifact) {
    Write-Host "[ERROR] Navratri_Utsav_iOS_IPA artifact not found in this run." -ForegroundColor Red
    exit 1
}

# Ensure destination folders exist
$distDir = Join-Path $PSScriptRoot "dist"
$iosDistDir = Join-Path $distDir "iOS"
if (-not (Test-Path $iosDistDir)) {
    New-Item -ItemType Directory -Path $iosDistDir -Force | Out-Null
}

# 4. Download and Extract the IPA
$zipDest = Join-Path $distDir "temp_ios_artifact.zip"
Write-Host "`n[4/4] Downloading iOS IPA artifact ($([Math]::Round($iosArtifact.size_in_bytes / 1MB, 2)) MB)..." -ForegroundColor White
Invoke-WebRequest -Uri $iosArtifact.archive_download_url -Headers $headers -OutFile $zipDest

Write-Host "Extracting Navratri_Utsav_iOS.ipa to dist/ and dist/iOS/..." -ForegroundColor White
tar -xf $zipDest -C $iosDistDir
Copy-Item (Join-Path $iosDistDir "Navratri_Utsav_iOS.ipa") -Destination (Join-Path $distDir "Navratri_Utsav_iOS.ipa") -Force
Remove-Item $zipDest -Force

$ipaFile = Get-Item (Join-Path $distDir "Navratri_Utsav_iOS.ipa")
Write-Host "`n========================================================" -ForegroundColor Green
Write-Host " [SUCCESS] iOS .IPA Successfully Stored in:" -ForegroundColor Green
Write-Host "   1. $($ipaFile.FullName) ($([Math]::Round($ipaFile.Length / 1MB, 2)) MB)" -ForegroundColor Yellow
Write-Host "   2. $(Join-Path $iosDistDir 'Navratri_Utsav_iOS.ipa')" -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Green
