function checkStack {
    param (
        $sleepPeriod = 5,
        $stackName,
        $stackRegion,
        $profileName,
        
        [ValidateSet("FromStart","AllEvents")]
        $loopType = 'FromStart'
    )

    # Default character lengths for the columns
    $preferredTimestampSpacing = 23
    $preferredResourceTypeSpacing = 27
    $preferredLogicalResourceIdSpacing = 27
    $preferredResourceStatusSpacing = 24

    # Calculated length for the ResourceStatusReason column
    $maxUiCharWidth = (Get-Host).UI.RawUI.BufferSize.Width
    $finalResourceStatusReasonSpacing = $maxUiCharWidth - ($preferredTimestampSpacing + $preferredResourceTypeSpacing + $preferredLogicalResourceIdSpacing + $preferredResourceStatusSpacing)

    # Headers for the output
    Write-Host 'Timestamp              ResourceType               LogicalResourceId          ResourceStatus         ResourceStatusReason'   
    Write-Host '---------              ------------               -----------------          --------------         --------------------' 

    # Set strings and arrays used in the loop
    $newArray = @()
    $workingArray = @()
    $loopThroughEvents = $true
    $startTime = Get-Date

    # While loopThroughEvents is true, loop the events and process them.
    while ($loopThroughEvents) {
        # Every 5 seconds, check the status of the stack
        Start-Sleep -Seconds $sleepPeriod
            
        # Query AWS to see what events are availanble for the stack
        if ($loopType -eq 'FromStart') {
            $newArray = Get-CFNStackEvent -StackName $stackName -Region $stackRegion -ProfileName $profileName | Where-Object {$_.Timestamp -ge $startTime} | Sort-Object -Property Timestamp
        }
        elseif ($loopType -eq 'AllEvents') {
            $newArray = Get-CFNStackEvent -StackName $stackName -Region $stackRegion -ProfileName $profileName | Sort-Object -Property Timestamp
        }
        $diffObjects = Compare-Object -ReferenceObject $workingArray -DifferenceObject $newArray -PassThru

        foreach ($object in $diffObjects) {
            ## Timestamp column
            $objTimestampSpacing          = ''.PadLeft($preferredTimestampSpacing)
            $objTimestamp                 = if ($object.Timestamp.ToString().length -ge ($objTimestampSpacing.length - 1)) {
                                                $object.Timestamp.ToString().Substring(0,($objTimestampSpacing.length - 1))
                                            }
                                            else {
                                                $object.Timestamp.ToString()
                                            }
            $objTimestampFinal            = $objTimestamp + $objTimestampSpacing.Substring(0,($objTimestampSpacing.length - $objTimestamp.length))
            Write-Host $objTimestampFinal -NoNewline

            ## ResourceType column
            $objResourceTypeSpacing       = ''.PadLeft($preferredResourceTypeSpacing)
            $objResourceType              = if ($object.ResourceType.ToString().length -ge ($objResourceTypeSpacing.length - 1)) {
                                                $object.ResourceType.ToString().Substring(0,($objResourceTypeSpacing.length - 1))
                                            }
                                            else {
                                                $object.ResourceType.ToString()
                                            }
            $objResourceTypeFinal         = $objResourceType + $objResourceTypeSpacing.Substring(0,($objResourceTypeSpacing.length - $objResourceType.length))
            Write-Host $objResourceTypeFinal -NoNewline

            ## LogicalResourceId column
            $objLogicalResourceIdSpacing  = ''.PadLeft($preferredLogicalResourceIdSpacing)
            $objLogicalResourceId         = if ($object.LogicalResourceId.ToString().length -ge ($objLogicalResourceIdSpacing.length - 1)) {
                                                $object.LogicalResourceId.ToString().Substring(0,($objLogicalResourceIdSpacing.length - 1))
                                            }
                                            else {
                                                $object.LogicalResourceId.ToString()
                                            }
            $objLogicalResourceIdFinal    = $objLogicalResourceId + $objLogicalResourceIdSpacing.Substring(0,($objLogicalResourceIdSpacing.length - $objLogicalResourceId.length))
            Write-Host $objLogicalResourceIdFinal -NoNewline

            ## LogicalResourceId column
            $objResourceStatusSpacing     = ''.PadLeft($preferredResourceStatusSpacing)
            $objResourceStatus            = if ($object.ResourceStatus.ToString().length -ge ($objResourceStatusSpacing.length - 1)) {
                                                $object.ResourceStatus.ToString().Substring(0,($objResourceStatusSpacing.length - 1))
                                            }
                                            else {
                                                $object.ResourceStatus.ToString()
                                            }
            $objResourceStatusFinal       = $objResourceStatus + $objResourceStatusSpacing.Substring(0,($objResourceStatusSpacing.length - $objResourceStatus.length))
            $statusColor = switch ($object.ResourceStatus.ToString()) {
                'CREATE_IN_PROGRESS' {'Green'}
                'UPDATE_IN_PROGRESS' {'Green'}
                'UPDATE_COMPLETE_CLEANUP_IN_PROGRESS' {'Green'}
                'DELETE_IN_PROGRESS' {'Yellow'}
                'CREATE_COMPLETE' {'Cyan'}
                'UPDATE_COMPLETE' {'Cyan'}
                'DELETE_COMPLETE' {'Cyan'}
                'CREATE_FAILED' {'DarkRed'}
                'ROLLBACK_IN_PROGRESS' {'Red'}
                'ROLLBACK_COMPLETE' {'Red'}
            }
            Write-Host $objResourceStatusFinal -NoNewline -ForegroundColor $statusColor

            ## ResourceStatusReason column
            $objResourceStatusReasonFinal = if ($object.ResourceStatusReason -and $finalResourceStatusReasonSpacing -gt 0) {
                                                if ($object.ResourceStatusReason.ToString().length -ge $finalResourceStatusReasonSpacing) {
                                                    $object.ResourceStatusReason.ToString().Substring(0,$finalResourceStatusReasonSpacing)
                                                }
                                                else {
                                                    $object.ResourceStatusReason.ToString()
                                                }
                                            }
                                            else {
                                                ''   
                                            }
            Write-Host $objResourceStatusReasonFinal

            ## Flag check to see if this is the end and set the stop if it is
            if ($object.ResourceType.ToString() -eq 'AWS::CloudFormation::Stack' -and ($object.ResourceStatus.ToString() -eq 'CREATE_COMPLETE' -or $object.ResourceStatus.ToString() -eq 'ROLLBACK_COMPLETE')) {
                $loopThroughEvents = $false
            }
        }
        # Populate the workingArray with the newArray data
        $workingArray = $newArray
    }
    #$workingArray | Write-Output
}

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
        [ValidateSet("Create","Update","Delete","Events")]
        [string]$Action,
        
        [parameter(Position=1,Mandatory=$true)]
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

        ### Create Action
        if ($Action -eq 'Create') {
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
            Write-Host 'Creating Stack' -ForegroundColor Cyan

            # Wait till the stack completes or fails
            checkStack -stackName $parameters.stackParameters.stackName -stackRegion $parameters.stackParameters.stackRegion -profileName $AWSProfileName -loopType FromStart
        }
        ### Update Action
        elseif ($Action -eq 'Update') {
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
            Write-Host 'Updating Stack' -ForegroundColor Cyan

            # Wait till the stack completes or fails
            checkStack -stackName $parameters.stackParameters.stackName -stackRegion $parameters.stackParameters.stackRegion -profileName $AWSProfileName -loopType FromStart
        }
        ### Delete Action
        elseif ($Action -eq 'Delete') {
            # Delete the stack
            Remove-CFNStack -StackName $parameters.stackParameters.stackName -Region $parameters.stackParameters.stackRegion -ProfileName $AWSProfileName -Confirm:$false
            Write-Host 'Removing Stack' -ForegroundColor Cyan

            # Wait till the stack completes or fails
            checkStack -stackName $parameters.stackParameters.stackName -stackRegion $parameters.stackParameters.stackRegion -profileName $AWSProfileName -sleepPeriod 2 -loopType FromStart
        }
        ### Events Action
        elseif ($Action -eq 'Events') {
            # Wait till the stack completes or fails
            checkStack -stackName $parameters.stackParameters.stackName -stackRegion $parameters.stackParameters.stackRegion -profileName $AWSProfileName -loopType AllEvents
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