Clear-Host
Write-Host "Asian PvP Community HWID Checker" -ForegroundColor Yellow
Write-Host "Made by " -ForegroundColor DarkGray -NoNewline
Write-Host "HadronCollision"
Write-Host ""

$processorId = "$((Get-WmiObject Win32_Processor).Name)"
$motherboardId = "$((Get-WmiObject win32_baseboard).Manufacturer) $((Get-WmiObject win32_baseboard).Product) $((Get-WmiObject win32_baseboard).SerialNumber)"
$ramId = "$((Get-WmiObject Win32_PhysicalMemory).Manufacturer) $((Get-WmiObject Win32_PhysicalMemory).PartNumber) $((Get-WmiObject Win32_PhysicalMemory).SerialNumber)"
$disksId = "$((Get-PhysicalDisk).FriendlyName) $((Get-PhysicalDisk).MediaType) $((Get-PhysicalDisk).Size) $((Get-PhysicalDisk).SerialNumber)"

$hwid = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$processorId | $motherboardId | $disksId | $ramId")).Replace("=", "") | Set-Clipboard
Write-Host "HWID copied to clipboard! Paste it into Discord using " -ForegroundColor White -NoNewline
Write-Host "Ctrl + V" -ForegroundColor Yellow
Write-Host
