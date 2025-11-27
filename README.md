# Profile Savior

![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)

**Profile Savior** is a PowerShell-based forensic tool designed to recover deleted user profiles from a machine's raw Recycle Bin artifacts. It is particularly useful for IT professionals recovering data after failed domain migrations, user profile corruption, or accidental deletions where the standard Restore interface is empty.

## How It Works
Windows obscures deleted files from other user profiles. Profile Savior parses the raw `$I` (Index) and `$R` (Data) files hidden in the system `C:\$Recycle.Bin` directory to:
1.  **Reconstruct** original filenames and folder paths from binary metadata.
2.  **Recover** files that standard Windows tools cannot see.
3.  **Repair** file extensions for orphans (files missing metadata) using Hex Signature analysis.

## Usage

```powershell
# Import the function
. .\ProfileSavior.ps1

# Run the recovery
Invoke-ProfileSavior -SourcePath "C:\Forensics\Raw_SID" -DestinationPath "C:\Forensics\Restored" -FixExtensions