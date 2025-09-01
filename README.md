# HabibiModAnalyzer

HabibiModAnalyzer is a screensharing tool for verifying the integrity of Minecraft mods.

## Usage

Run the following command in **PowerShell** to execute HabibiModAnalyzer:

```powershell
powershell -Command "Set-ExecutionPolicy Bypass -Scope Process; Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/HadronCollision/PowershellScripts/refs/heads/main/HabibiModAnalyzer.ps1')"
```

## Features
- **Hash Verification**
  - Computes file hashes and checks them against **Modrinth’s API**.
  - Uses a **custom database** (called `megabase`) for mods not listed on Modrinth.

- **Cheat Detection**
  - Scans mods and their dependency jars for **common cheat strings**.

- **Download Source Identification**
  - Inspects **Zone.Identifier metadata** to determine the original source of a file.

## Megabase
The `megabase` database currently contains hashes for:
- `InventoryHUD+`
- `ReplayMod`

The API is publicly accessible. Example query:
https://megabase.vercel.app/api/query?hash=3C7A9AC6DB0D246A90B1443EB840A377B28EB0CF

If you would like to suggest mods to add to the megabase, reach out on discord: **hadroncollision**
