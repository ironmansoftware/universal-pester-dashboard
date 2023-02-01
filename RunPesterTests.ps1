param($File)

Invoke-Pester -Path $File -PassThru | ConvertTo-Json -Depth 5 -WarningAction SilentlyContinue

