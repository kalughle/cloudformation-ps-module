# cloudformation-ps-module

Description

---

## Functionality

- Creates a Stack using parameters defined in a custom parameters file
- Deletes a Stack using parameters defined in a custom parameters file
- Updates a Stack using parameters defined in a custom parameters file

### Current Limitations

- Does not currently support StackSets
- Does not currently support most Stack options

---

## Install

1. Copy the _/powershell/cfmod.psm1_ file to any location of your choosing.
2. Run the command `Import-Module <path-to-module>`.

---

## Parameters File
XXX

### File Example
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

### Stack Parameters
This section of the json file defines the **Stack** itself. It is used for configuring Stack options, and not for inputs to the template itself. All parameters in this section are **required**. 
- **stackName**: Any string you choose to become the full Stack name.
  - *Type*: String
- **stackTemplate**: The path to the **json** or **yaml** template you want to use.
  - *Type*: String
  - *Example*: `"..\\templates\\tmplt_config_role.yaml"`
  - *IMPORTANT*: Note that the "\" character in the path must be escaped by placing another "\" in front of each.
- **stackRegion**: The region, in AWS format, that you want to build the stack in.
  - *Type*: String
  - *Example*: `"us-west-2"`
- **isIamStack**: This is a stack option that you must set to true if you are creating IAM resources. There is a checkbox for this option in the GUI when attempting to make the same resource that corresponds directly to this option.
  - *Type*: String
  - *Example*: `"false"`
  - *Allowed*: `"true"` or `"false"`

### Template Parameters
- _yourParam1_: xxx
- _yourParam2_: xxx

## Usage

XXX `command` YYY

---

## Credentials

### AWS

XXX You can use one of the [standard AWS CLI credential mechanisms](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html).

---

## Dependencies

XXX
- cloud-nuke uses `dep`, a vendor package management tool for golang. See the dep repo for
  [installation instructions](https://github.com/golang/dep). cloud-nuke currently does not support Go modules.

---

## License

This code is released under the MIT License. See [LICENSE.txt](/LICENSE.txt).