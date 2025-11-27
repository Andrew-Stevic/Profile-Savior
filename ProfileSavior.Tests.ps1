Describe "Profile Savior Integrity Check" {
    BeforeAll {
        $TargetFileName = "ProfileSavior.ps1"
        $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath $TargetFileName
        if (-not (Test-Path $ScriptPath)) { Write-Host "CRITICAL: Cannot find $ScriptPath" -ForegroundColor Red }
    }
    Context "File Artifacts" {
        It "File should exist" { $ScriptPath | Should -Exist }
        It "Syntax should be valid" { $ScriptPath | Should -HaveValidScriptSyntax }
    }
    Context "Functionality" {
        It "Should load without crashing" { { . $ScriptPath } | Should -Not -Throw }
        It "Function should be exported" { . $ScriptPath; Get-Command -Name "Invoke-ProfileSavior" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty }
    }
}
