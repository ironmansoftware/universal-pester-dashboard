$Dashboard = New-UDPage -Name 'Pester Dashboard' -Id 'page' -Content {
    $Jobs = , (Get-PSUScript 'RunPesterTests.ps1' -Integrated | Get-PSUJob -OrderBy EndTime -First 10 -Integrated)
    for ($i = 0; $i -lt $Jobs.length; $i++) {
        $Pipeline = $Jobs[$i] | Get-PSUJobPipelineOutput -Integrated
        $Output = [string]::Join("`r`n", $Pipeline) | ConvertFrom-Json
        $Jobs[$i] = $Jobs[$i] | Add-Member -Name 'Pipeline' -MemberType NoteProperty -Value $Output -PassThru
    }

    New-UDRow -Columns {
        New-UDColumn -LargeSize 6 -Content {
            New-UDCard -Title "Last 10 Runs - Failed Tests" -Content {
                $Failed = @{
                    Status = 'Failed'
                    Count  = ($Jobs.Pipeline.FailedCount | Measure-Object -Sum).Sum
                }
                $Passed = @{
                    Status = 'Passsed'
                    Count  = ($Jobs.Pipeline.PassedCount | Measure-Object -Sum).Sum
                }

                New-UDChartJS -Type Pie -Data @($Failed, $Passed) -DataProperty 'Count' -LabelProperty 'Status' -BackgroundColor @('#b5211e', '#307a1e')
            }
        }
        New-UDColumn -LargeSize 6 -Content {
            New-UDRow -Columns {
                New-UDColumn -Content {
                    New-UDTable -Title 'Test Runs' -Data $Jobs -Columns @(
                        New-UDTableColumn -Property 'StartTime' -Title 'Time' -Render { New-UDDateTime $EventData.StartTime }
                        New-UDTableColumn -Property 'Script' -Title 'Container' -Render { $EventData.Pipeline.Containers | ForEach-Object { [IO.Path]::GetFileName($_.Item.FullName) } }
                        New-UDTableColumn -Property 'Result' -Title 'Result' -Render { $EventData.Pipeline.Result }
                        New-UDTableColumn -Property 'FailedCount' -Title 'Failed Tests' -Render { New-UDTypography $EventData.Pipeline.FailedCount }
                        New-UDTableColumn -Property 'PassedCount' -Title 'Passed Tests' -Render { New-UDTypography $EventData.Pipeline.PassedCount }
                        New-UDTableColumn -Property 'Job' -Title 'Output' -Render { 
                            New-UDButton -Text "View" -OnClick { 
                                Invoke-UDRedirect -Url "/run/$($EventData.Id)"
                            } -Icon (New-UDIcon -Icon 'Eye')
                        }
                    ) -ShowPagination

                    $TestScripts = Get-ChildItem "*.Tests.ps1" 
                    New-UDTable -Title 'Test Containers' -Data $TestScripts -Columns @(
                        New-UDTableColumn -Property 'Name' -Title 'Name'
                        New-UDTableColumn -Property 'Run' -Title 'Run' -Render {
                            New-UDButton -Text 'Run' -Icon (New-UDIcon -Icon 'Play') -OnClick {
                                $Job = Invoke-PSUScript -Name 'RunPesterTests.ps1' -Integrated -File $EventData.Name 
                                Show-UDModal -Content {
                                    New-UDProgress -Circular 
                                    New-UDTypography "Running tests..."
                                    
                                }
                                $Job | Wait-PSUJob -Integrated
                                Hide-UDModal
                                Invoke-UDRedirect -Url "/run/$($Job.Id)"
                            }
                        }
                    )
                }
            }
        }
    }
}

$TestRun = New-UDPage -Name 'Test Run' -Url "/run/:id" -Content {
    $Job = Get-PSUJob -Id $Id -Integrated
    $Pipeline = $Job | Get-PSUJobPipelineOutput -Integrated
    $Output = $Pipeline | ConvertFrom-Json
    $Job = $Job | Add-Member -Name 'Pipeline' -MemberType NoteProperty -Value $Output -PassThru

    New-UDCard -Title 'Details' -Content {
        New-UDTypography "Job Id: $Id" -Variant h5
        New-UDTypography "Start Time: $($Job.StartTime)" -Variant h5
        New-UDTypography ("Container: " + ($Job.Pipeline.Containers | ForEach-Object { [IO.Path]::GetFileName($_.Item.FullName) })) -Variant h5
    }

    New-UDTable -Title 'Passed Tests' -Data $Job.Pipeline.Passed -Columns @(
        New-UDTableColumn -Title 'Name' -Property 'ExpandedPath'
        New-UDTableColumn -Title 'Timestamp' -Property 'ExecutedAt' -Render { New-UDDateTime $EventData.ExecutedAt }
    ) -ShowPagination -Icon (New-UDIcon -Icon 'CheckCircle' -Color green)

    New-UDTable -Title 'Failed Tests' -Data $Job.Pipeline.Failed -Columns @(
        New-UDTableColumn -Title 'Name' -Property 'ExpandedPath'
        New-UDTableColumn -Title 'Timestamp' -Property 'ExecutedAt' -Render { New-UDDateTime $EventData.ExecutedAt }
        New-UDTableColumn -Title 'Error' -Property 'ErrorRecord' -Render { 
            $EventData.ErrorRecord.Exception.Message
        }
    ) -ShowPagination -Icon (New-UDIcon -Icon 'TimesCircle' -Color red)
}

New-UDDashboard -Title 'Pester' -Pages @($Dashboard, $TestRun)