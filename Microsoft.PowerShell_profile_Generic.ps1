
# Git Helpers

function Invoke-GitPullAll {
    Get-ChildItem "$HOME\git" -Directory |
        Where-Object { Test-Path "$($_.FullName)\.git" } |
        ForEach-Object {
            Write-Host "==> $($_.Name)" -ForegroundColor Cyan
            git -C $_.FullName pull
        }
}
 
function Invoke-GitPushAll {
    Get-ChildItem "$HOME\git" -Directory |
        Where-Object { Test-Path "$($_.FullName)\.git" } |
        ForEach-Object {
            Write-Host "==> $($_.Name)" -ForegroundColor Cyan
            git -C $_.FullName commit --allow-empty -m "empty commit"
            if ($LASTEXITCODE -eq 0) { git -C $_.FullName push }
        }
}
 
# Show a one-line git status for every repo under ~/git
function Get-GitStatusAll {
    Get-ChildItem "$HOME\git" -Directory |
        Where-Object { Test-Path "$($_.FullName)\.git" } |
        ForEach-Object {
            $branch = git -C $_.FullName rev-parse --abbrev-ref HEAD 2>$null
            $dirty  = git -C $_.FullName status --porcelain 2>$null
            $state  = if ($dirty) { "dirty" } else { "clean" }
            $color  = if ($dirty) { "Yellow" } else { "Green" }
            Write-Host ("{0,-25} {1,-15} {2}" -f $_.Name, $branch, $state) -ForegroundColor $color
        }
}
 
Set-Alias gpull  Invoke-GitPullAll
Set-Alias gpush  Invoke-GitPushAll
Set-Alias gstat  Get-GitStatusAll


# Jump straight into ~/git
function repos { Set-Location "$HOME\git" }
 
# Open the current folder in Explorer:  `open` or `open <path>`
function open { param($p = ".") Invoke-Item $p }
 
# UTF-8 everywhere (avoids garbled output from git, etc.)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
 
# Make Ctrl+D exit like a Unix shell
Set-PSReadLineKeyHandler -Chord Ctrl+d -Function DeleteCharOrExit -ErrorAction SilentlyContinue

