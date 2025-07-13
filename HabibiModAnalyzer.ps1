Clear-Host
Write-Host "Habibi Mod Analyzer" -ForegroundColor Yellow
Write-Host "Made by " -ForegroundColor DarkGray -NoNewline
Write-Host "HadronCollision"
Write-Host

Write-Host "Enter path to the mods folder: " -NoNewline
Write-Host "(press Enter to use default)" -ForegroundColor DarkGray
$mods = Read-Host "PATH"
Write-Host

if (-not $mods) {
    $mods = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
	Write-Host "Continuing with " -NoNewline
	Write-Host $mods -ForegroundColor White
	Write-Host
}

if (-not (Test-Path $mods -PathType Container)) {
    Write-Host "Invalid Path!" -ForegroundColor Red
    exit 1
}

$process = Get-Process javaw -ErrorAction SilentlyContinue
if (-not $process) {
    $process = Get-Process java -ErrorAction SilentlyContinue
}

if ($process) {
    try {
        $startTime = $process.StartTime
        $elapsedTime = (Get-Date) - $startTime
    } catch {}

    Write-Host "{ Minecraft Uptime }" -ForegroundColor DarkCyan
    Write-Host "$($process.Name) PID $($process.Id) started at $startTime and running for $($elapsedTime.Hours)h $($elapsedTime.Minutes)m $($elapsedTime.Seconds)s"
    Write-Host ""
}

function Get-SHA1 {
    param (
        [string]$filePath
    )
    return (Get-FileHash -Path $filePath -Algorithm SHA1).Hash
}

function Get-ZoneIdentifier {
    param (
        [string]$filePath
    )
	$ads = Get-Content -Raw -Stream Zone.Identifier $filePath -ErrorAction SilentlyContinue
	if ($ads -match "HostUrl=(.+)") {
		return $matches[1]
	}
	
	return $null
}

function Fetch-Modrinth {
    param (
        [string]$hash
    )
    try {
        $response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version_file/$hash" -Method Get -UseBasicParsing -ErrorAction Stop
		if ($response.project_id) {
            $projectResponse = "https://api.modrinth.com/v2/project/$($response.project_id)"
            $projectData = Invoke-RestMethod -Uri $projectResponse -Method Get -UseBasicParsing -ErrorAction Stop
            return @{ Name = $projectData.title; Slug = $projectData.slug }
        }
    } catch {}
	
    return @{ Name = ""; Slug = "" }
}

function Fetch-Megabase {
    param (
        [string]$hash
    )
    try {
        $response = Invoke-RestMethod -Uri "https://megabase.vercel.app/api/query?hash=$hash" -Method Get -UseBasicParsing -ErrorAction Stop
		if (-not $response.error) {
			return $response.data
		}
    } catch {}
	
    return $null
}

$cheatStrings = @(
	"AimAssist",
	"AnchorTweaks",
	"AutoAnchor",
	"AutoCrystal",
	"AutoAnchor",
	"AutoDoubleHand",
	"AutoHitCrystal",
	"AutoPot",
	"AutoTotem",
	"AutoArmor",
	"InventoryTotem",
	"Hitboxes",
	"JumpReset",
	"LegitTotem",
	"PingSpoof",
	"SelfDestruct",
	"ShieldBreaker",
	"TriggerBot",
	"Velocity",
	"AxeSpam",
	"WebMacro",
	"SelfDestruct",
	"FastPlace"
)

function Check-Strings {
	param (
        [string]$filePath
    )
	
	$stringsFound = [System.Collections.Generic.HashSet[string]]::new()
	
	$fileContent = Get-Content -Raw $filePath
	
	foreach ($line in $fileContent) {
		foreach ($string in $cheatStrings) {
			if ($line -match $string) {
				$stringsFound.Add($string) | Out-Null
				continue
			}
		}
	}
	
	return $stringsFound
}


$verifiedMods = @()
$unknownMods = @()
$cheatMods = @()

$jarFiles = Get-ChildItem -Path $mods -Filter *.jar

$spinner = @("|", "/", "-", "\")
$totalMods = $jarFiles.Count
$counter = 0

foreach ($file in $jarFiles) {
	$counter++
	$spin = $spinner[$counter % $spinner.Length]
	Write-Host "`r[$spin] Scanning mods: $counter / $totalMods" -ForegroundColor Yellow -NoNewline
	
	$hash = Get-SHA1 -filePath $file.FullName
	
    $modDataModrinth = Fetch-Modrinth -hash $hash
    if ($modDataModrinth.Slug) {
		$verifiedMods += [PSCustomObject]@{ ModName = $modDataModrinth.Name; FileName = $file.Name }
		continue;
    }
	
	$modDataMegabase = Fetch-Megabase -hash $hash
	if ($modDataMegabase.name) {
		$verifiedMods += [PSCustomObject]@{ ModName = $modDataMegabase.Name; FileName = $file.Name }
		continue;
	}
	
	$zoneId = Get-ZoneIdentifier $file.FullName
	$unknownMods += [PSCustomObject]@{ FileName = $file.Name; FilePath = $file.FullName; ZoneId = $zoneId }
}

if ($unknownMods.Count -gt 0) {
	$tempDir = Join-Path $env:TEMP "habibimodanalyzer"
	
	$counter = 0
	
	try {
		if (Test-Path $tempDir) {
			Remove-Item -Recurse -Force $tempDir
		}
		
		New-Item -ItemType Directory -Path $tempDir | Out-Null
		Add-Type -AssemblyName System.IO.Compression.FileSystem
	
		foreach ($mod in $unknownMods) {
			$counter++
			$spin = $spinner[$counter % $spinner.Length]
			Write-Host "`r[$spin] Scanning unknown mods for cheat strings..." -ForegroundColor Yellow -NoNewline
			
			$modStrings = Check-Strings $mod.FilePath
			if ($modStrings.Count -gt 0) {
				$unknownMods = @($unknownMods | Where-Object -FilterScript {$_ -ne $mod})
				$cheatMods += [PSCustomObject]@{ FileName = $mod.FileName; StringsFound = $modStrings }
				continue
			}
			
			$fileNameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($mod.FileName)
			$extractPath = Join-Path $tempDir $fileNameWithoutExt
			New-Item -ItemType Directory -Path $extractPath | Out-Null
			
			[System.IO.Compression.ZipFile]::ExtractToDirectory($mod.FilePath, $extractPath)
			
			$depJarsPath = Join-Path $extractPath "META-INF/jars"
			if (-not $(Test-Path $depJarsPath)) {
				continue
			}
			
			$depJars = Get-ChildItem -Path $depJarsPath
			foreach ($jar in $depJars) {
				$depStrings = Check-Strings $jar.FullName
				if (-not $depStrings) {
					continue
				}
				$unknownMods = @($unknownMods | Where-Object -FilterScript {$_ -ne $mod})
				$cheatMods += [PSCustomObject]@{ FileName = $mod.FileName; DepFileName = $jar.Name; StringsFound = $depStrings }
			}
			
		}
	} catch {
		Write-Host "Error occured while scanning jar files! $($_.Exception.Message)" -ForegroundColor Red
	} finally {
		Remove-Item -Recurse -Force $tempDir
	}
}

Write-Host "`r$(' ' * 80)`r" -NoNewline

if ($verifiedMods.Count -gt 0) {
	Write-Host "{ Verified Mods }" -ForegroundColor DarkCyan
	foreach ($mod in $verifiedMods) {
		Write-Host ("> {0, -30}" -f $mod.ModName) -ForegroundColor Green -NoNewline
		Write-Host "$($mod.FileName)" -ForegroundColor Gray
	}
	Write-Host
}

if ($unknownMods.Count -gt 0) {
	Write-Host "{ Unknown Mods }" -ForegroundColor DarkCyan
	foreach ($mod in $unknownMods) {
		if ($mod.ZoneId) {
			Write-Host ("> {0, -30}" -f $mod.FileName) -ForegroundColor DarkYellow -NoNewline
			Write-Host "$($mod.ZoneId)" -ForegroundColor DarkGray
			continue
		}
		Write-Host "> $($mod.FileName)" -ForegroundColor DarkYellow
	}
	Write-Host
}

if ($cheatMods.Count -gt 0) {
Write-Host "{ Cheat Mods }" -ForegroundColor DarkCyan
	foreach ($mod in $cheatMods) {
		Write-Host "> $($mod.FileName)" -ForegroundColor Red -NoNewline
		if ($mod.DepFileName) {
			Write-Host " ->" -ForegroundColor Gray -NoNewline
			Write-Host " $($mod.DepFileName)" -ForegroundColor Red -NoNewline
		}
		Write-Host " [$($mod.StringsFound)]" -ForegroundColor DarkMagenta
	}
	Write-Host
}
