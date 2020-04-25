# cloudformation-ps-module

Description

## Functionality

- Creates a Stack using parameters defined in a custom parameters file
- Deletes a Stack using parameters defined in a custom parameters file
- Updates a Stack using parameters defined in a custom parameters file

#### Current Limitations

- Does not currently support StackSets
- Does not currently support most Stack options

## Install

1. Copy the /powershell/cfmod.psm1 file to any location of your choosing.
2. Run the command 'Import-Module <path-to-module>'.

## Parameter File

```
{
    "stackParameters": {
        "stackName":     "cf-usw2-configrole",
        "stackTemplate": "..\\templates\\tmplt_config_role.yaml",
        "stackRegion":   "us-west-2",
        "isIamStack":    "true"
    },
    "templateParameters": {
        "iamRemediationRoleName": "configremediationrole",
        "snsTopicName": "configremediationtopic",
        "snsDisplayName": "config-rem"
    }
}
```

#### Stack Parameters

XXX

#### Template Parameters

XXX

## Usage

XXX `command` YYY

## Credentials

#### AWS

XXX You can use one of the [standard AWS CLI credential mechanisms](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html).

## Dependencies

XXX
- cloud-nuke uses `dep`, a vendor package management tool for golang. See the dep repo for
  [installation instructions](https://github.com/golang/dep). cloud-nuke currently does not support Go modules.

## License

This code is released under the MIT License. See [LICENSE.txt](/LICENSE.txt).