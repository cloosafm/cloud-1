# work with terraform and gcp:

## some resources:
https://www.youtube.com/watch?v=nvV6yobU710&list=PLpZQVidZ65jO_wtOpLv-HmC9uJgTRB8GT&index=2
https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/google-cloud-platform-build
https://www.hashicorp.com/resources/ansible-terraform-better-together


## set up application default credentials:
use gcloud cli:
`gcloud auth application-default login`

## initialize directory
`terraform init`

This command is used when creating a new config, or when checking out existing config from version control. It will download the existing providers defined in the config, and initializes the directory.


## format and validate the config
`terraform fmt`
Ensures the config is syntactically valid.

## create infrastructure
`terraform apply`

Terraform indicates infrastructure changes it plans to make, and pause to await approval.
If anything seems weird, incorrect, dangerous... it is safe to stop here.
If it all looks good, type `yes`


## config state
Terraform has versioning tools, it stores 'states' for the config in a file called terraform.tfstate
To inspect current state: `terraform show`

## changing infrastructure
If new resources are added to the conf (or if existing ones are modified), they can be provisioned with :
`terraform apply`

## destroy infrastructure
When the infrastructure is no longer needed, they can be destroyed to reduce security exposure as well as costs.
You want to use:
`terraform destroy`
This command terminates the resources specified in the terraform state. Resources running elsewhere and NOT managed by current terraform project WILL NOT be destroyed.
This is the inverse of `terraform apply`, and just like it, it needs approval to be executed.
Again, need to type `yes` to execute the command.


## variables - how to declare and define them
variable can be defined in the same conf file, but usually are are defined in a separate variables.tf file
In the conf file, use of variable will be noted as `project = var.var_name` instead of `project = "hard-coded-value"`

the var_name is an identifier that can contain letters, digits, underscores (_), and hyphens (-). The first character of an identifier must not be a digit, to avoid ambiguity with literal numbers.

The var_name can be any valid identifier except the following, as these are reserved for meta-arguments in module configuration blocks:
"source", "version", "providers", "count", "for_each", "lifecycle", "depends_on", "locals"

In the var file, the var_name are minimally defined as :
`variable "<var_name>" {}`
But it can also take a default value between the curly brackets:
```hcl
variable "<var_name>" {
  default = "<default_value>"
}
```

If a default value is defined, it means the variable is optional : there is no need to declare a specific value anywhere else. If there is no default value, then the var value will need to be given in any of the following ways:
  - as env variables : `export TF_VAR_<var_name>=<var_value>`
  - as CLI args when running terraform `terraform apply -var <var_name>=<var_value>`
  - using a file called exactly terraform.tfvars or terraform.tfvars.json or any file ending in either .auto.tfvars or .auto.tfvars.json that will be automatically called when creating the infrastructure
  - using a specific file and calling it on CLI `terraform apply -var-file="<filename>"` (it seems that filename must be ending in .tfvars or tfvars.json ?)
Obviously, you can have a default in the variables.tf file and also give it a definition in the .tfvars file


## variables - options
`
The possible options are as follows:
    default - A default value which then makes the variable optional.

    type - This argument specifies what value types are accepted for the variable. This is optional but recommended, as it is helpful for error management

    description - This specifies the input variable's documentation. This is intended for users' documentation. For commentary for module maintainers, use comments.

    validation - A block to define validation rules, usually in addition to type constraints.

    ephemeral - This variable is available during runtime, but not written to state or plan files.

    sensitive - Limits Terraform UI output when the variable is used in configuration.

    nullable - Specify if the variable can be null within the module.

*There is no fixed order, but according to Copilot a common convention would be:*
- *description*
- *type*
- *default*
- *validation*
- *sensitive*
- *nullable*

Here is an example of using options :
```hcl
  variable "<var_name>" {
    type = list(number)
    description = "This is a description from the end user's perspective"
    default = [12, "34.6"]
    validation {
      condition = <returns true or false, depending on value of variable>
      error_message = <string : full sentence explaining the error, strting with upper-case letter and ending with period or question mark>
    }
}
```

## variables - more on types
There are 3 simple types (string, number, bool) and 5 complex types (list, set, map, object, tuple).
It is also possible to indicate :
  `type = any` so that any type can be used
  `type = null` which seems useful for conditional expressions ? in case the condition is not met
A list or a tuple can contain elements of different types, or be constrained to a single type.
A set can contain only one type of variables, cannot contain repetitions, and will be ordered automatically. A map also can only contain one type of variables.
List, set and map are collection types, tuple and objects are structural types. You can also use one general complex variable type to hold values for multiple elements.

### example 1 : with a tuple
Here is an example with a tuple:
```hcl
variable "vm_params" {
  type = tuple([string, string, bool])
  description = "vm parameters"
  default = ["f1-micro", "us-central1-a", true]
}
```
Then in the main.tf file, you would declare the instance resources as follows:
```hcl
resource "google_compute_instance" "my_instance" {
  name         = "terraform-instance"
  machine_type = var.vm_params[0]
  zone         = var.vm_params[1]
  allow_stopping_for_update = var.vm_params[2]
}
```

### example 1 : with an object
Another example, with an object :
```hcl
variable "my_object" {

  type = object({
    name = string
    machine_type = string
    zone = string
    allow_stopping_for_update = bool
    disk = object({
      source_image = string
      auto_delete = bool
      boot = bool
    })
  })

  default = {
    project = "cloud-1"
    machine_type = "f1-micro"
    zone = "us-central1-a"
    allow_stopping_for_update = true
    disk = {
      source_image = "ubuntu-os-cloud/ubuntu-2204-lts"
      auto_delete = true
      boot = true
    }
  }

  validation {
    condition = length(var.my_object.name) > 4 
    error_message = "VM name must be at least 4 characters."
  }
}
```

Then in the main.tf file, you would declare the instance resources as follows:
```hcl
resource "google_compute_instance" "my_instance" {
  name         = var.my_object.name
  machine_type = var.vm_params.machine_type
  zone         = var.vm_params.zone
  allow_stopping_for_update = var.vm_params.allow_stopping_for_update
  disk {
      source_image = var.my_object.source_image
      auto_delete = var.my_object.auto_delete
      boot = var.my_object.boot
  }
}
```

*the part with the 'disk' variable was only shown defined in variable.tf, but not its main.tf declaration, so may not be correct*