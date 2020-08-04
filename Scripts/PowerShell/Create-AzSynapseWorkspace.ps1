<#
.History
   28/07/2020 - 1.0 - Initial release - David Alzamendi
.Synopsis
   Create Azure Synapse Analytics Workspace
.DESCRIPTION
    This script creates an Azure Synapse Analytics Workspace using the following cmdlets
    Pre-requirements:
                    AzModule ----> Install-Module -Name Az.Synapse
                    Be connected to Azure ----> Connect-AzAccount 
    Module descriptions are in https://docs.microsoft.com/en-us/powershell/module/az.synapse/new-azsynapseworkspace?view=azps-4.4.0
.EXAMPLE
   Create-AzSynapseWorkspace -ResourceGroupName "" -Name "" -Location "" -DefaultDataLakeStorageAccountName "" -DefaultDataLakeStorageFilesystem "" -AdminSqlLogin "" -AdminSqlPwd ""
   Create-AzSynapseWorkspace -ResourceGroupName "" -Name "" -Location "" -DefaultDataLakeStorageAccountName "" -DefaultDataLakeStorageFilesystem "" -AdminSqlLogin "" -AdminSqlPwd "" -DefaultTags -TagEnvironment "" -TagBusinessUnit ""

#>
[CmdletBinding()]
param (
   [Parameter(Mandatory=$true)]
   [string]$ResourceGroupName ="",
   
   [Parameter(Mandatory=$true)]
   [string]$Name = "",

   [Parameter(Mandatory=$true)]
   [string]$Location = "",
   
   [Parameter(Mandatory=$true)]
   [string]$DefaultDataLakeStorageAccountName = "",

   [Parameter(Mandatory=$true)]
   [string]$DefaultDataLakeStorageFilesystem = "",

   [Parameter(Mandatory=$true)] 
   [string]$AdminSqlLogin = "",

   [Parameter(Mandatory=$true)]
   [string]$AdminSqlPwd ="",

   # Tags
   [switch]$DefaultTags,
   [string]$TagEnvironment = "",
   [string]$TagBusinessUnit = ""



)
 
Begin
    {
        

            write-host "Starting creation of Azure Synapse Analytics on $(Get-Date)"
        
            # Convert credentials
            $Pwd = ConvertTo-SecureString $AdminSqlPwd -AsPlainText -Force
            $Creds = New-Object System.Management.Automation.PSCredential ($AdminSqlLogin, $Pwd)

            if($PSBoundParameters.ContainsKey('DefaultTags')) {
            
                write-host "Adding tags"

                # Check if values have been defined
                 if(($TagEnvironment -eq "") -or  ($TagBusinessUnit -eq ""))
                 {

                    throw "Values for the default tags TagEnvironment and TagBusinessUnit need to be defined."

                 }

                 # Get User Account
                $TagCreatedBy =  Get-AzContext | Select-Object  Account | Format-Table -HideTableHeaders | Out-String 
                  
                 
                # Define tags
                $AllTags = @{BusinessUnit=$TagBusinessUnit;Environment=$TagEnvironment;CreatedBy=$TagCreatedBy.Trim()}

                $AzureSynParams = @{
                "ResourceGroupName" = $ResourceGroupName
                "Location" = $Location
                "Name" = $Name
                "DefaultDataLakeStorageAccountName" = $DefaultDataLakeStorageAccountName
                "DefaultDataLakeStorageFilesystem" = $DefaultDataLakeStorageFilesystem
                "SqlAdministratorLoginCredential" = $Creds
                "Tag" = $AllTags
                }


            }
            else 
            {
               # Create Azure Synapse Analytics without tags
                $AzureSynParams = @{
                "ResourceGroupName" = $ResourceGroupName
                "Location" = $Location
                "Name" = $Name
                "DefaultDataLakeStorageAccountName" = $DefaultDataLakeStorageAccountName
                "DefaultDataLakeStorageFilesystem" = $DefaultDataLakeStorageFilesystem
                "SqlAdministratorLoginCredential" = $Creds
            }

        }


        }
Process 
    {
        # Check if exists
        Get-AzSynapseWorkspace -ResourceGroupName $ResourceGroupName -Name $Name -ErrorVariable DoesNotExist -ErrorAction SilentlyContinue

        if ($DoesNotExist)
        {

            New-AzSynapseWorkspace @AzureSynParams

        }
        else
        {

            throw "Synapse Analytics Workspace $Name already exists."

        }

    }
End
    {
        write-host "Finish on $(Get-Date)"
    }
