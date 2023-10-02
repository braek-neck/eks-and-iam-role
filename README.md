# Terraform to deploy EKS and IRSA

## Requirements
#### Software
The following software must be installed in order to carry out the deployment process:

* AWS CLI v2
* eksctl
* kubectl
* terrafrom

#### Network stack
Based on the AWS best practices, the following network resources should be in place (in the target AWS region) prior to the deployment process:

* VPC
    * DNS hostnames must be enabled
    * DNS resolution must be enabled
* Internet gateway
* 3 public subnets
* 3 private subnets
* 3 NAT gateways (or 1 NAT gateway for non-prod environment)
* Properly configured route tables

## Deploy AWS EKS
##### Configure aws-cli to access you aws account.
[Here](http:/https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html/ "Here") is an instruction how to configure aws-cli. You have to use method that is uses in your company.

##### Prepare backend for terraform state
Use init-backend terraform to create s3 bucket and DunamoDB table.
To apply terraform, simply run the following commands on your command console.

    cd init-backend
    terraform init
    terrafrom plan
    terrafrom apply

After running the command, a new s3 bucket and dynamoDB table will be created. The output will provide a configured template to be used in the terraform code for configuring the backend.

```json
terraform {
          backend "s3" {
            bucket         = "00000000000-us-east-1-terraform-state"
            key            = "STACKNAME/terraform.tfstate"
            region         = "us-east-1"
            dynamodb_table = "terraform-state-locktable"
            encrypt        = true
          }
        }

```
Replace the 'STACKNAME' placeholder with a unique name for each stack within your bucket.

##### Deploy EKS cluster


