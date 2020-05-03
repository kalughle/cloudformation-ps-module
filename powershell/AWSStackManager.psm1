function Use-AWSStackManager {
    <#
    .SYNOPSIS
    Creates, Updates or Deletes an AWS Stack from a Parameter file.

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
    None. You cannot pipe objects to Use-AWSStackManager.

    .OUTPUTS
    None

    .EXAMPLE
    PS> Use-AWSStackManager -Action Create -ParamFileName .\param_file.json -AWSProfileName builduser 
    
    This command uses the "builduser" profile to build a stack within the file "param_file.json" in this directory

    .EXAMPLE
    PS> Use-AWSStackManager -Action Update -ParamFileName .\param_file.json -AWSProfileName builduser 
    
    This command uses the "builduser" profile to update a stack within the file "param_file.json" in this directory

    .EXAMPLE
    PS> Use-AWSStackManager -Action Delete -ParamFileName .\param_file.json -AWSProfileName builduser 
    
    This command uses the "builduser" profile to delete a stack within the file "param_file.json" in this directory

    .EXAMPLE
    PS> Use-AWSStackManager -Action Events -ParamFileName .\param_file.json -AWSProfileName builduser 
    
    This command uses the "builduser" profile to pull all events for a stack within the file "param_file.json" in this directory

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

        # Store the current directory and change to the new one. (Do not use pushd/popd)
        $startingPath = (Get-Location).Path
        $paramFileObject = Get-ChildItem $ParamFileName
        
        Set-Location $paramFileObject.DirectoryName
        $paramFile = '.\' + $paramFileObject.Name
        
        # Import the AWS PS Module
        Import-Module AWSPowerShell
        
        # If no AWSProfileName variable is defined, pull the variable from the AWS_PROFILE environment variable
        if (!$AWSProfileName) {
            $AWSProfileName = (Get-ChildItem Env:AWS_PROFILE).Value
        }

        # Pull the preferences file and convert it from JSON to PSObject
        $parameters = Get-Content $paramFile -Raw | ConvertFrom-Json

        # Test basic connectivity. No failure check because the try/catch block catches it
        Write-Host 'Testing basic connectivity...' -NoNewLine
        if (Get-CFNStack -ProfileName $AWSProfileName) {
            Write-Host PASSED -ForegroundColor Green
        }

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
            if($parameters.stackParameters.isIamStack = 'true') {
                New-CFNStack -StackName $parameters.stackParameters.stackName -TemplateBody $template -Parameter $allParams -Region $parameters.stackParameters.stackRegion -Capability 'CAPABILITY_NAMED_IAM' -ProfileName $AWSProfileName | Out-Null
            }
            else {
                New-CFNStack -StackName $parameters.stackParameters.stackName -TemplateBody $template -Parameter $allParams -Region $parameters.stackParameters.stackRegion -ProfileName $AWSProfileName | Out-Null
            }
            Write-Host 'Creating Stack' -ForegroundColor Cyan

            # Set date markers
            $refTime = Get-Date

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

            # Set date markers by referencing the last event in the stack, then sleep to force a delay
            $refTime = (Get-CFNStackEvent -StackName $parameters.stackParameters.stackName -Region $parameters.stackParameters.stackRegion -ProfileName $AWSProfileName | Sort-Object -Property Timestamp | Select-Object -Last 1).Timestamp
            Start-Sleep -Seconds 2

            # Create the new stack
            if($parameters.stackParameters.isIamStack = 'true') {
                Update-CFNStack -StackName $parameters.stackParameters.stackName -TemplateBody $template -Parameter $allParams -Region $parameters.stackParameters.stackRegion -Capability 'CAPABILITY_NAMED_IAM' -ProfileName $AWSProfileName | Out-Null
            }
            else {
                Update-CFNStack -StackName $parameters.stackParameters.stackName -TemplateBody $template -Parameter $allParams -Region $parameters.stackParameters.stackRegion -ProfileName $AWSProfileName | Out-Null
            }
            Write-Host 'Updating Stack' -ForegroundColor Cyan

            # Wait till the stack completes or fails
            checkStack -stackName $parameters.stackParameters.stackName -stackRegion $parameters.stackParameters.stackRegion -profileName $AWSProfileName -refTime $refTime -loopType FromStart
        }
        ### Delete Action
        elseif ($Action -eq 'Delete') {
            # Set date markers by referencing the last event in the stack, then sleep to force a delay
            $refTime = (Get-CFNStackEvent -StackName $parameters.stackParameters.stackName -Region $parameters.stackParameters.stackRegion -ProfileName $AWSProfileName | Sort-Object -Property Timestamp | Select-Object -Last 1).Timestamp
            Start-Sleep -Seconds 2
            
            # Delete the stack
            Remove-CFNStack -StackName $parameters.stackParameters.stackName -Region $parameters.stackParameters.stackRegion -ProfileName $AWSProfileName -Confirm:$false
            Write-Host 'Removing Stack' -ForegroundColor Cyan
            
            # Wait till the stack completes or fails
            checkStack -stackName $parameters.stackParameters.stackName -stackRegion $parameters.stackParameters.stackRegion -profileName $AWSProfileName -refTime $refTime -sleepPeriod 2 -loopType FromStart
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
    finally {
        Set-Location $startingPath
    }
}

function checkStack {
    param (
        $sleepPeriod = 5,
        $refTime,
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
    Write-Host ''
    Write-Host 'Timestamp              ResourceType               LogicalResourceId          ResourceStatus         ResourceStatusReason'   
    Write-Host '---------              ------------               -----------------          --------------         --------------------' 

    # Set strings and arrays used in the loop
    $newArray = @()
    $workingArray = @()
    $loopThroughEvents = $true

    # While loopThroughEvents is true, loop the events and process them.
    while ($loopThroughEvents) {
        # Every <variable> seconds, check the status of the stack
        Start-Sleep -Seconds $sleepPeriod
            
        # Query AWS to see what events are available for the stack
        if ($loopType -eq 'FromStart') {
            $newArray = Get-CFNStackEvent -StackName $stackName -Region $stackRegion -ProfileName $profileName | Where-Object {$_.Timestamp -gt $refTime} | Sort-Object -Property Timestamp
        }
        elseif ($loopType -eq 'AllEvents') {
            $newArray = Get-CFNStackEvent -StackName $stackName -Region $stackRegion -ProfileName $profileName | Sort-Object -Property Timestamp
        }
        
        # Do a diff on the new list and the old list
        $diffObjects = Compare-Object -ReferenceObject $workingArray -DifferenceObject $newArray -PassThru

        # Loop through the diffs in order, writing each column. (This needs to be a function - Fix it!!!!)
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
            # If you see the error "Cannot bind parameter 'ForegroundColor' to the target.", you likely need to add an Event Status and color to the Switch below
            $statusColor = switch ($object.ResourceStatus.ToString()) {
                'CREATE_IN_PROGRESS' {'Green'}
                'UPDATE_IN_PROGRESS' {'Green'}
                'UPDATE_COMPLETE_CLEANUP_IN_PROGRESS' {'Green'}
                'DELETE_IN_PROGRESS' {'Yellow'}
                'DELETE_SKIPPED' {'Yellow'}
                'CREATE_COMPLETE' {'Cyan'}
                'UPDATE_COMPLETE' {'Cyan'}
                'DELETE_COMPLETE' {'Cyan'}
                'CREATE_FAILED' {'DarkRed'}
                'UPDATE_FAILED' {'DarkRed'}
                'UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS' {'Red'}
                'UPDATE_ROLLBACK_IN_PROGRESS' {'Red'}
                'UPDATE_ROLLBACK_COMPLETE' {'Red'}
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

            ## Flag check to see if this is the end and set the stop the loop if it is
            if ($object.ResourceType.ToString() -eq 'AWS::CloudFormation::Stack' `
                -and ($object.ResourceStatus.ToString() -eq 'CREATE_COMPLETE' `
                      -or $object.ResourceStatus.ToString() -eq 'ROLLBACK_COMPLETE' `
                      -or $object.ResourceStatus.ToString() -eq 'UPDATE_COMPLETE' `
                      -or $object.ResourceStatus.ToString() -eq 'UPDATE_ROLLBACK_COMPLETE')) {
                $loopThroughEvents = $false
            }
        }
        # Populate the workingArray with the newArray data
        $workingArray = $newArray
    }
    #$workingArray | Write-Output
}

Export-ModuleMember -Function Use-AWSStackManager