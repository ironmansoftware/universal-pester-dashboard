New-PSUDashboard -Name "Pester" -FilePath "dashboards\Pester\Pester.ps1" -BaseUrl "/pester" -Framework "UniversalDashboard:Latest" -SessionTimeout 0 -AutoDeploy -Credential "Default"