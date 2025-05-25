Clear-Host
Write-Host "Country Checker" -ForegroundColor Yellow
Write-Host "Made by " -ForegroundColor DarkGray -NoNewline
Write-Host "HadronCollision"
Write-Host ""

$vpn = Get-NetAdapter | Where-Object { -not $_.MacAddress -and $_.Status -eq "Up" } | Select-Object -ExpandProperty Name

$ipInfo = Invoke-RestMethod -Uri "https://api.ip2location.io/" -UseBasicParsing
if ($ipInfo -and $ipInfo.country_name) {
    Write-Host "Country: $($ipInfo.country_name)" -ForegroundColor DarkCyan
} else {
    Write-Host "Could not retrieve country information."
}

if ($vpn -or $ipInfo.is_proxy) {
	Write-Host ""
    Write-Host "VPN Detected!!!" -ForegroundColor Red
    Write-Host "- $vpn" -ForegroundColor DarkGray
}

Write-Host ""

$motherboardId = (Get-WmiObject win32_baseboard).SerialNumber
$disksId = (Get-Disk).SerialNumber
$hwid = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$motherboardId $disksId")).Replace("=", "")
Write-Host "HWID: $hwid" -ForegroundColor Cyan

Write-Host ""
