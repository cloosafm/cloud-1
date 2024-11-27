# work with terraform and gcp:


## set up application default credentials:
use gcloud cli:
```
gcloud auth application-default login
```

## initialize directory
```
terraform init
```

This command is used when creating a new config, or when checking out existing config from version control. It will download the existing providers defined in the config, and initializes the directory.


## format and validate the config
```
terraform fmt
```
Ensures the config is syntactically valid.

## create infrastructure
```
terraform apply
```

Terraform indicates infrastructure changes it plans to make, and pause to await approval.
If anything seems weird, incorrect, dangerous... it is safe to stop here.
If it all looks good, type 
```
yes
```


## config state
Terraform has versioning tools, it stores 'states' for the config in a file called terraform.tfstate
To inspect current state:
```
terraform show
```

## changing infrastructure
If new resources are added to the conf (or if existing ones are modified), they can be provisioned with
```
terraform apply
```

## destroy infrastructure
when the infrastructure is no longer needed, they can be destroyed to reduce security exposure as well as costs.
```
terraform destroy
```
This command terminates the resources specified in the terraform state. Resources running elsewhere and NOT managed by current terraform project WILL NOT be destroyed.
This is the inverse of 
```
terraform apply
```
and just like it, it needs approval to be executed.
Again, need to type 
```
yes
```
to execute the command.


## variables
variable can be defined in the same conf file, but usually are are defined in a separate variables.tf file
In the conf file, use of variable will be noted as 
```
project = var.var_name
```
instead of 
```
project = "hard-coded-value"
```

In the var file, they are minimally defined as
```
variable "<var_name>" {}
```
but can also take a default value between the curly brackets:
```

variable "<var_name>" {
  default = "<default_value>"
}
```

If a default value is defined, it means the variable is optional : there is no need to declare a specific value anywhere else. If there is no default value, then the var value will need to be given in any of the following ways:
  - as env variables
```
export TF_VAR_<var_name>=<var_value>
```
  - as CLI args when running terraform
	```
terraform apply -var <var_name>=<var_value>
```
  - using a file called exactly terraform.tfvars or terraform.tfvars.json or any file ending in either .auto.tfvars or .auto.tfvars.json that will be automatically called when creating the infrastructure
  - using a specific file and calling it on CLI
```
terraform apply -var-file="<filename>"
```
(seems that filename must be ending in .tfvars or tfvars.json ?)
