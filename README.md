# cloudformation-ps-module

A **PowerShell** module and **Custom JSON Template** combination, used to deploy, update and remove [AWS CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html) Stacks using the [AWS Tools for PowerShell](https://aws.amazon.com/powershell/) module. The PS module *AWSStackManager.psm1* is designed to read through the contents of the custom json template and use the parameters set there to build and configure your [Standard CloudFormation Template](https://aws.amazon.com/cloudformation/resources/templates/) in to a Stack. This module will work with any standard CloudFormation template. 

---

## Functionality

- **Creates** a Stack using parameters defined in the custom parameters file
- **Deletes** a Stack using parameters defined in the custom parameters file
- **Updates** a Stack using parameters defined in the custom parameters file
- **Reports Events** in a Stack using parameters defined in the custom parameters file

### Current Limitations

- Does not currently support StackSets
- Does not currently support most Stack options

### Available Functions

- Use-AWSStackManager

---

## Install

1. Copy the _/powershell/AWSStackManager.psm1_ file to any location of your choosing.
2. Run the command `Import-Module <path-to-module>`.

---

## Parameters File

The parameter file is a **json** formatted file that the **AWSStackManager.psm1** module parses through in order to build your stack. It is comprised of two sections:
1. The *Stack Patameters* section: A defined structure of **required** parameters that identifies the template file and configures the Stack itself.
2. The *Template Parameters* section: Defined by the template you are using and the input parameters in that template. The *Template Parameters* section can have any number of parameters.

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

This section of the json file defines the **Stack** itself. It is used for configuring Stack options, and not for inputs to the template. All parameters in this section are **required**.

- **stackName**: Any string you choose to become the full Stack name.
  - *Type*: String
- **stackTemplate**: The path to the **json** or **yaml** template you want to use. This should be either an *absolute path* or a path *relative to the paramater file*.
  - *Type*: String
  - *Example*: `"..\\templates\\tmplt_config_role.yaml"`
  - *IMPORTANT*: Note that the "\\" character in the path must be escaped by placing another "\\" in front of each.
- **stackRegion**: The region, in AWS format, that you want to build the stack in.
  - *Type*: String
  - *Example*: `"us-west-2"`
- **isIamStack**: This is a stack option that you must set to true only if you are **creating IAM resources**. *There is a checkbox for this option in the GUI when attempting to make the same resource that corresponds directly to this option in the cli*.
  - *Type*: String
  - *Example*: `"false"`
  - *Allowed*: `"true"` or `"false"`

### Template Parameters
This section of the json file is completely dependant on the **Parameters** section of your CloudFormation template. 
- You will need one (1) key-value pair in this section for each parameter you want to define. 
- The *Key* should match one of your input parameters, and the *Value* should be the value you want that parameter set to in your stack.
- If you want to use a *Default Parameter* already set in the template you must **omit** the *Key* from the parameter file. If you set the *Value* to `""`, the module will attempt to place a null value in the parameter (*Most parameters do not accept this type of input*).
- If you have **no** parameters you wish to input, simply **omit** all key-value pairs from this section. The section itself **must** reamin.

---

## Usage

### Create a New Stack (Using -AWSProfileName parameter)
- This command uses the "builduser" profile in the AWS *config* or *credentials* file to build a stack with the file "param_file.json" in the current directory
- `PS> Use-AWSStackManager -Action Create -ParamFileName .\param_file.json -AWSProfileName builduser`

### Create a New Stack (Using AWS_PROFILE environment variable)
- This command uses a profile from the AWS *config* or *credentials* file that has been set in the environment variable `AWS_PROFILE` to build a stack with the file "param_file.json" in the current directory
- `PS> Use-AWSStackManager -Action Create -ParamFileName .\param_file.json`

### Deleting or Updating a Stack
- The same syntax used for creating a **New** stack can be used for **Updating** or **Removing** (Deleting) a stack.
- `PS> Use-AWSStackManager -Action Update -ParamFileName .\param_file.json -AWSProfileName builduser`
- `PS> Use-AWSStackManager -Action Update -ParamFileName .\param_file.json`
- `PS> Use-AWSStackManager -Action Delete -ParamFileName .\param_file.json -AWSProfileName builduser`
- `PS> Use-AWSStackManager -Action Delete -ParamFileName .\param_file.json`

### Reading All Events in a Stack
- The same syntax used for creating a **New** stack can be used for **Reading All Events** in a stack.
- `PS> Use-AWSStackManager -Action Events -ParamFileName .\param_file.json -AWSProfileName builduser`
- `PS> Use-AWSStackManager -Action Events -ParamFileName .\param_file.json`

---

## Working Example
This repository has a working example of a template and parameters file. The template is very simple and creates an SNS topic and IAM role. Both require inputs that are defined in the parameters file. The commands found above in the **Usage** section can be used to build with these files. 

***Note***: If you move the files from their respective locations, you **must** update the *stackTemplate* parameter within the *stackParameters* section inside the **Parameters File**.

### Files
- Parameters File: `cloudformation-ps-module/parameters/param_file.json`
- Template File: `cloudformation-ps-module/templates/tmplt_config_role.yaml`

---

## Credentials

### AWS

Currently, the **AWSStackManager.psm1** module only supports using a **profile** in the AWS *config* or *credentials* file (One of the [standard AWS CLI credential mechanisms](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)). You can use this functionality in one of two ways:
1. Use the `-AWSProfileName` parameter in any of the commands to select a profile from the *config* or *credentials* files
2. Set the environment variable `AWS_PROFILE` to a profile in the *config* or *credentials* files

---

## Dependencies

- The `AWSStackManager.psm1` module uses the **AWS Tools for PowerShell** module to make API calls to AWS. See the AWS page for
  [installation instructions](https://aws.amazon.com/powershell/).

---

## License

This code is released under the MIT License. See [LICENSE](/LICENSE).