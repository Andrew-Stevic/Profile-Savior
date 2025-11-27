<#
.SYNOPSIS
    Profile Savior - Forensic Recycle Bin Recovery Utility
.DESCRIPTION
    Recover deleted files from raw Windows Recycle Bin artifacts ($I/$R files).
.LICENSE
    Copyright (C) 2025
    Licensed under the GNU Affero General Public License v3.0 (AGPLv3).
#>
function Invoke-ProfileSavior {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
    param (
        [Parameter(Mandatory=$true, Position=0)][string]$SourcePath,
        [Parameter(Mandatory=$true, Position=1)][string]$DestinationPath,
        [switch]$FixExtensions
    )

    # --- HELPER: Parse Metadata ---
    function Get-OriginalPath {
        param ([string]$MetadataPath)
        try {
            $ByteStream = [System.IO.File]::ReadAllBytes($MetadataPath)
            if ($ByteStream.Length -le 24) { return $null }
            $PathBytes = $ByteStream[24..($ByteStream.Length - 1)]
            $UnicodeString = [System.Text.Encoding]::Unicode.GetString($PathBytes)
            $SplitPath = $UnicodeString.Split('\')
            return $SplitPath[-1].Trim([char]0)
        }
        catch { return $null }
    }

    # --- HELPER: Magic Numbers ---
    function Repair-FileSignature {
        param ([string]$FilePath)
        if ([System.IO.Path]::GetExtension($FilePath)) { return } 
        try {
            $Stream = [System.IO.File]::OpenRead($FilePath); $Header = New-Object byte[] 4; [void]$Stream.Read($Header, 0, 4); $Stream.Close()
            $HexSig = ($Header | ForEach-Object { $_.ToString("X2") }) -join ""
            $NewExt = switch -Wildcard ($HexSig) {
                "89504E47" { ".png" }; "FFD8FF*" { ".jpg" }; "25504446" { ".pdf" }; "504B0304" { ".docx" }; "D0CF11E0" { ".doc" }; "00000024" { ".3gp" }; "494433*" { ".mp3" }
            }
            if ($NewExt) { Rename-Item -Path $FilePath -NewName ($FilePath + $NewExt) -Force }
        } catch {}
    }

    # --- MAIN FLOW ---
    Write-Host "=== PROFILE SAVIOR ===" -ForegroundColor Cyan
    if (-not (Test-Path $DestinationPath)) { New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null }
    
    $Artifacts = Get-ChildItem -Path $SourcePath -Filter '$I*' -File -Force
    Write-Host "Analyzing $($Artifacts.Count) artifacts..." -ForegroundColor Yellow

    foreach ($MetaFile in $Artifacts) {
        $DataFileName = $MetaFile.Name -replace '^\$I', '$R'
        $DataFilePath = Join-Path -Path $SourcePath -ChildPath $DataFileName
        
        if (Test-Path $DataFilePath) {
            $RestoredName = Get-OriginalPath -MetadataPath $MetaFile.FullName
            if ([string]::IsNullOrWhiteSpace($RestoredName) -or $RestoredName -match "^[a-zA-Z]:$") { $RestoredName = "Unknown_" + $MetaFile.BaseName.Substring(2) }
            
            $TargetFile = Join-Path -Path $DestinationPath -ChildPath $RestoredName
            if (Test-Path $TargetFile) { $TargetFile = Join-Path -Path $DestinationPath -ChildPath ("$([System.IO.Path]::GetFileNameWithoutExtension($RestoredName))_" + $MetaFile.BaseName.Substring(2) + $([System.IO.Path]::GetExtension($RestoredName))) }

            if (Test-Path $DataFilePath -PathType Container) { if (-not (Test-Path $TargetFile)) { New-Item -ItemType Directory -Path $TargetFile -Force | Out-Null }; Copy-Item -Path "$DataFilePath\*" -Destination $TargetFile -Recurse -Force }
            else { Copy-Item -Path $DataFilePath -Destination $TargetFile -Force }
        }
    }

    # Orphans
    $OrphanPath = Join-Path $DestinationPath "Orphans"
    Get-ChildItem -Path $SourcePath -Filter '$R*' -File -Force | ForEach-Object {
        $ExpectedMeta = $_.Name -replace '^\$R', '$I'
        if (-not (Test-Path (Join-Path $SourcePath $ExpectedMeta))) {
            if (-not (Test-Path $OrphanPath)) { New-Item -ItemType Directory -Path $OrphanPath -Force | Out-Null }
            Copy-Item -Path $_.FullName -Destination (Join-Path $OrphanPath $_.Name) -Force
        }
    }

    # Extensions
    if ($FixExtensions) { Get-ChildItem -Path $DestinationPath -Recurse -File | ForEach-Object { Repair-FileSignature -FilePath $_.FullName } }
    Write-Host "Done." -ForegroundColor Green
}
