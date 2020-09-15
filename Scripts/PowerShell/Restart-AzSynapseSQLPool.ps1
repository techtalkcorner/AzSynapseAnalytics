 <#
.History
   15/09/2020 - 1.0 - Initial release - David Alzamendi
.Synopsis
   Start/Pause/Restart Azure Synapse Analytics SQL Pool
.DESCRIPTION
    This script starts/pauses or restarts an Azure Synapse Analytics SQL Pool
    Pre-requirements:
                    AzModule ----> Install-Module -Name Az.Synapse
                    Be connected to Azure ----> Connect-AzAccount 
    Module descriptions are in https://docs.microsoft.com/en-us/powershell/module/az.sql/?view=azps-4.6.1

.PARAMETERS 
•	ResourceGroupName: resource group name where the server is being hosted
•	ServerName server name that needs to be restarted
•	DatabaseName: database name that needs to be restarted
•	Operation: it needs to be Start/Pause or Restart



Operation parameter values:
                            Pause
                            Start
                            Restart

.EXAMPLE
   Restart-AzSynapseSQLPool -ResourceGroupName "" -ServerName "" -DatabaseName "" -Operation ""
   
#>

[CmdletBinding()]
param (
   [Parameter(Mandatory=$true)]
   [string]$ResourceGroupName ="",
   
   [Parameter(Mandatory=$true)]
   [string]$ServerName = "",

   [Parameter(Mandatory=$true)]
   [string]$DatabaseName = "",

   [Parameter(Mandatory=$true)]
   [string]$Operation = ""

)


Begin
    {

    # Validation parameters
    $ArrayOperations = "Pause","Start","Restart"

     If ($Operation -notin $ArrayOperations)
     {
           Throw "Only Pause, Start, Restart Operations are valid"
    }

    # Start
    write-host "Starting process on $(Get-Date)"

    $Status = Get-AzSqlDatabase –ResourceGroupName $ResourceGroupName –ServerName $ServerName –DatabaseName $DatabaseName | Select-Object Status | Format-Table -HideTableHeaders | Out-String 


}
Process 
    {
    # Start block
        if(($Operation -eq "Start") -and ($Status.trim() -ne "Online")){
            write-host "Starting"$Operation "Operation"

                     try 
                    {  
                        write-host "Starting on $(Get-Date)"
                         Get-AzSqlDatabase –ResourceGroupName $ResourceGroupName –ServerName $ServerName –DatabaseName $DatabaseName | Resume-AzSqlDatabase
                    }
                    catch
                    {
                         write-host "Error while executing "$Operation
                    }

  
        }
    # Pause block
        if(($Operation -eq "Pause") -and ($Status.trim() -ne "Paused")){
            write-host "Starting"$Operation "Operation"

                      try 
                    {  
                        write-host "Pausing on $(Get-Date)"
                        Get-AzSqlDatabase –ResourceGroupName $ResourceGroupName –ServerName $ServerName –DatabaseName $DatabaseName | Suspend-AzSqlDatabase
                    }
                    catch
                    {
                         write-host "Error while executing "$Operation
                    }

  
        }
        # Restart block
        if(($Operation -eq "Restart") -and ($Status.trim() -eq "Online")){
            write-host "Starting"$Operation "Operation"

                    try 
                    {  
                        write-host "Pausing on $(Get-Date)"
                        Get-AzSqlDatabase –ResourceGroupName $ResourceGroupName –ServerName $ServerName –DatabaseName $DatabaseName | Suspend-AzSqlDatabase

                        write-host "Starting on $(Get-Date)"
                        Get-AzSqlDatabase –ResourceGroupName $ResourceGroupName –ServerName $ServerName –DatabaseName $DatabaseName | Resume-AzSqlDatabase
                    }
                    catch
                    {
                         write-host "Error while executing "$Operation
                    }


  
        }

}

End
    {
    # Exit
        write-host "Finished process on $(Get-Date)"
    }

