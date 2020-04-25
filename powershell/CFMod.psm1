function New-AWSStack {
    <#
    .SYNOPSIS
    Creates an AWS Stack from a Parameter file.

    .DESCRIPTION
    XXX

    .PARAMETER ParamFileName
    Specifies the file name for the custom JSON parameters file. 
    The format of this file can be found in the Readme for this repo. 
    
    https://github.com/kalughle/cloudformation-ps-module

    .PARAMETER AWSProfileName
    Specifies the profile name from your AWS Config Or Credentials file that you would like to use. 
    If omitted, this parameter is populated with the AWS_PROFILE environment variable.

    .INPUTS
    None. You cannot pipe objects to New-AWSStack.

    .OUTPUTS
    None

    .EXAMPLE
    PS> New-AWSStack -ParamFileName .\param_file.json -AWSProfileName builduser 
    
    This command uses the "builduser" profile to build a stack with the file "param_file.json" in this directory

    .LINK
    https://github.com/kalughle/cloudformation-ps-module
    #>

    param (
        [parameter(Position=0,Mandatory=$true)]
        [string]$ParamFileName,

        [parameter()]
        [string]$AWSProfileName
    )

    try {
        # Set EAP. This forces any error to become a "terminating" error
        $ErrorActionPreference = 'Stop'
        
        # Import the AWS PS Module
        Import-Module AWSPowerShell
        
        # If no AWSProfileName variable is defined, pull the variable from the AWS_PROFILE environment variable
        if (!$AWSProfileName) {
            $AWSProfileName = (Get-ChildItem Env:AWS_PROFILE).Value
        }

        # Pull the preferences file and convert it from JSON to PSObject
        $parameters = Get-Content $ParamFileName -Raw | ConvertFrom-Json

        # Pull the CloudFormation Template from a JSON file in RAW format
        $template = Get-Content $parameters.stackParameters.stackTemplate -Raw
    
        # Loop through the templateParameters in the parameters file and create CloudFormation Parameters
        $allParams = @()
        foreach ($fileProperty in ($parameters.templateParameters | Get-Member | Where-Object {$_.MemberType -eq "NoteProperty"}).Name) {
            $params = New-Object -TypeName Amazon.CloudFormation.Model.Parameter
            $params.ParameterKey = $fileProperty
            $params.ParameterValue = $parameters.templateParameters.$fileProperty
            $allParams += $params
        }
        
        # Create the new stack
        if( $parameters.stackParameters.isIamStack = 'true') {
            $stackArn = New-CFNStack -StackName $parameters.stackParameters.stackName -TemplateBody $template -Parameter $allParams -Region $parameters.stackParameters.stackRegion -Capability 'CAPABILITY_NAMED_IAM' -ProfileName $AWSProfileName
        }
        else {
            $stackArn = New-CFNStack -StackName $parameters.stackParameters.stackName -TemplateBody $template -Parameter $allParams -Region $parameters.stackParameters.stackRegion -ProfileName $AWSProfileName
        }
        Write-Host 'Creating Stack:' -ForegroundColor Cyan -NoNewline

        # Wait till the stack completes or fails
        while ($objectStatus -notlike "*_COMPLETE" -and $objectStatus -notlike "*_FAILED") {
            # Every 5 seconds, check the status of the stack
            Start-Sleep -Seconds 5
            $objectStatus = (Get-CFNStackSummary -Region $parameters.stackParameters.stackRegion -ProfileName $AWSProfileName | Where-Object {$_.StackId -eq $stackArn}).StackStatus
            
            # Host Reporting logic
            if ($objectStatus -like "*ROLLBACK_COMPLETE") {
                Write-Host $objectStatus -ForegroundColor Red
                Remove-AWSStack -ParamFileName $ParamFileName -AWSProfileName $AWSProfileName
            }
            elseif ($objectStatus -like "*_COMPLETE") {
                Write-Host $objectStatus -ForegroundColor Green
            }
            elseif ($objectStatus -like "*_FAILED") {
                Write-Host $objectStatus -ForegroundColor Red
            }
            else {
                Write-Host '.' -NoNewline
            }
        }
    }
    catch {
        Write-Error $_
        break
    }
}

function Remove-AWSStack {
    <#
    .SYNOPSIS
    Deletes an AWS Stack from a Parameter file.

    .DESCRIPTION
    XXX

    .PARAMETER ParamFileName
    Specifies the file name for the custom JSON parameters file. 
    The format of this file can be found in the Readme for this repo. 
    
    https://github.com/kalughle/cloudformation-ps-module

    .PARAMETER AWSProfileName
    Specifies the profile name from your AWS Config Or Credentials file that you would like to use. 
    If omitted, this parameter is populated with the AWS_PROFILE environment variable.

    .INPUTS
    None. You cannot pipe objects to Remove-AWSStack.

    .OUTPUTS
    None

    .EXAMPLE
    PS> Remove-AWSStack -ParamFileName .\param_file.json -AWSProfileName builduser 
    
    This command uses the "builduser" profile to delete a stack with the file "param_file.json" in this directory

    .LINK
    https://github.com/kalughle/cloudformation-ps-module
    #>

    param (
        [parameter(Position=0,Mandatory=$true)]
        [string]$ParamFileName,

        [parameter()]
        [string]$AWSProfileName
    )

    try {
        # Set EAP. This forces any error to become a "terminating" error
        $ErrorActionPreference = 'Stop'
        
        # Import the AWS PS Module
        Import-Module AWSPowerShell
        
        # If no AWSProfileName variable is defined, pull the variable from
        # the AWS_PROFILE environment variable
        if (!$AWSProfileName) {
            $AWSProfileName = (Get-ChildItem Env:AWS_PROFILE).Value
        }

        # Pull the preferences file and break the 2 sections
        $parameters = Get-Content $ParamFileName -Raw | ConvertFrom-Json

        # Delete the stack
        Remove-CFNStack -StackName $parameters.stackParameters.stackName -Region $parameters.stackParameters.stackRegion -ProfileName $AWSProfileName -Confirm:$false
        Write-Host 'Removing Stack:' -ForegroundColor Cyan -NoNewline

        # Wait till the stack completes or fails
        while ($objectStatus -notlike "*_COMPLETE" -and $objectStatus -notlike "*_FAILED") {
            # Every 5 seconds, check the status of the stack
            Start-Sleep -Seconds 5
            $objectStatus = (Get-CFNStackSummary -Region $parameters.stackParameters.stackRegion -ProfileName $AWSProfileName | Where-Object {$_.StackName -eq $parameters.stackParameters.stackName} | Sort-Object -Property CreationTime -Descending)[0].StackStatus
            
            # Host Reporting logic
            if ($objectStatus -like "*_COMPLETE") {
                Write-Host $objectStatus -ForegroundColor Green
            }
            elseif ($objectStatus -like "*_FAILED") {
                Write-Host $objectStatus -ForegroundColor Red
            }
            else {
                Write-Host '.' -NoNewline
            }
        }
    }
    catch {
        Write-Error $_
        break
    }
}

function Update-AWSStack {
    <#
    .SYNOPSIS
    Updates an AWS Stack from a Parameter file.

    .DESCRIPTION
    XXX

    .PARAMETER ParamFileName
    Specifies the file name for the custom JSON parameters file. 
    The format of this file can be found in the Readme for this repo. 
    
    https://github.com/kalughle/cloudformation-ps-module

    .PARAMETER AWSProfileName
    Specifies the profile name from your AWS Config Or Credentials file that you would like to use. 
    If omitted, this parameter is populated with the AWS_PROFILE environment variable.

    .INPUTS
    None. You cannot pipe objects to Update-AWSStack.

    .OUTPUTS
    None

    .EXAMPLE
    PS> Update-AWSStack -ParamFileName .\param_file.json -AWSProfileName builduser 
    
    This command uses the "builduser" profile to update a stack with the file "param_file.json" in this directory

    .LINK
    https://github.com/kalughle/cloudformation-ps-module
    #>

    param (
        [parameter(Position=0,Mandatory=$true)]
        [string]$ParamFileName,

        [parameter()]
        [string]$AWSProfileName
    )

    try {
        # Set EAP. This forces any error to become a "terminating" error
        $ErrorActionPreference = 'Stop'
        
        # Import the AWS PS Module
        Import-Module AWSPowerShell
        
        # If no AWSProfileName variable is defined, pull the variable from the AWS_PROFILE environment variable
        if (!$AWSProfileName) {
            $AWSProfileName = (Get-ChildItem Env:AWS_PROFILE).Value
        }

        # Pull the preferences file and convert it from JSON to PSObject
        $parameters = Get-Content $ParamFileName -Raw | ConvertFrom-Json

        # Pull the CloudFormation Template from a JSON file in RAW format
        $template = Get-Content $parameters.stackParameters.stackTemplate -Raw
    
        # Loop through the templateParameters in the parameters file and create CloudFormation Parameters
        $allParams = @()
        foreach ($fileProperty in ($parameters.templateParameters | Get-Member | Where-Object {$_.MemberType -eq "NoteProperty"}).Name) {
            $params = New-Object -TypeName Amazon.CloudFormation.Model.Parameter
            $params.ParameterKey = $fileProperty
            $params.ParameterValue = $parameters.templateParameters.$fileProperty
            $allParams += $params
        }
        
        # Create the new stack
        if( $parameters.stackParameters.isIamStack = 'true') {
            $stackArn = Update-CFNStack -StackName $parameters.stackParameters.stackName -TemplateBody $template -Parameter $allParams -Region $parameters.stackParameters.stackRegion -Capability 'CAPABILITY_NAMED_IAM' -ProfileName $AWSProfileName
        }
        else {
            $stackArn = Update-CFNStack -StackName $parameters.stackParameters.stackName -TemplateBody $template -Parameter $allParams -Region $parameters.stackParameters.stackRegion -ProfileName $AWSProfileName
        }
        Write-Host 'Updating Stack:' -ForegroundColor Cyan -NoNewline

        # Wait till the stack completes or fails
        while ($objectStatus -notlike "*_COMPLETE" -and $objectStatus -notlike "*_FAILED") {
            # Every 5 seconds, check the status of the stack
            Start-Sleep -Seconds 5
            $objectStatus = (Get-CFNStackSummary -Region $parameters.stackParameters.stackRegion -ProfileName $AWSProfileName | Where-Object {$_.StackId -eq $stackArn}).StackStatus
            
            # Host Reporting logic
            if ($objectStatus -like "*_COMPLETE") {
                Write-Host $objectStatus -ForegroundColor Green
            }
            elseif ($objectStatus -like "*_FAILED") {
                Write-Host $objectStatus -ForegroundColor Red
            }
            else {
                Write-Host '.' -NoNewline
            }
        }
    }
    catch {
        Write-Error $_
        break
    }
}