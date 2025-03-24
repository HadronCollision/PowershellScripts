Clear-Host
Write-Host "Country Checker" -ForegroundColor Yellow
Write-Host "Made by " -ForegroundColor DarkGray -NoNewline
Write-Host "HadronCollision"
Write-Host ""

$vpn = Get-NetAdapter | Where-Object { -not $_.MacAddress -and $_.Status -eq "Up" } | Select-Object -ExpandProperty Name

if ($vpn) {
    Write-Host "VPN Detected!!!" -ForegroundColor Red
    Write-Host "- $vpn" -ForegroundColor DarkGray
    Write-Host ""
    exit
}

$ipInfo = Invoke-RestMethod -Uri "https://ipinfo.io" -UseBasicParsing
if ($ipInfo -and $ipInfo.country) {
    Write-Host "Country: $($ipInfo.country)" -ForegroundColor DarkCyan
} else {
    Write-Host "Could not retrieve country information."
}

Write-Host ""
