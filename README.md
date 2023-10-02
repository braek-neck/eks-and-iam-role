# Terraform to deploy EKS and IRSA
## Description

This project aims to simplify the process of setting up an EKS cluster. Additionally, instructions are provided below on how to create an IRSA role and use it to access an S3 bucket from a pod.

Prerequisites for installation include an AWS EKS cluster. Optional components include a [AWS Load Balancer Controller](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html "AWS Load Balancer Controller") and [Cluster Autoscaler](https://docs.aws.amazon.com/eks/latest/userguide/autoscaling.html "Autoscaler").

[IRSA - IAM roles for service accounts.](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html "IRSA - IAM roles for service accounts.") Applications in a Pod's containers can use an AWS SDK or the AWS CLI to make API requests to AWS services using AWS Identity and Access Management (IAM) permissions. Applications must sign their AWS API requests with AWS credentials. IAM roles for service accounts provide the ability to manage credentials for your applications, similar to the way that Amazon EC2 instance profiles provide credentials to Amazon EC2 instances. Instead of creating and distributing your AWS credentials to the containers or using the Amazon EC2 instance's role, you associate an IAM role with a Kubernetes service account and configure your Pods to use the service account.

## Requirements
#### Software
The following software must be installed in order to carry out the deployment process:

* [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html "AWS CLI v2")
* [kubectl](https://kubernetes.io/docs/tasks/tools/ "kubectl")
* [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli "terraform")

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
#### Configure aws-cli to access you aws account.
[Here](http:/https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html/ "Here") is an instruction how to configure aws-cli. You have to use method that is uses in your company.

#### Prepare backend for terraform state
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

#### Configure
Before running Terraform, you must enter the data obtained above in the backend.tf file. Additionally, create a file with the variable values as shown in the example.tfvars file.
You can access a comprehensive description of all available variables in the variables.tf file.

Please ensure you carefully consider the node-group parameters.

    eks_managed_node_groups = {
      main = {
        min_size     = 1
        max_size     = 3
        desired_size = 2
        instance_types = ["t3.medium"]
      }
    }

Choose the instance type that is most suitable for your requirements, and remember that it can be changed later. Determine the minimum, maximum, and current values for the number of instances.
If you set the `enable_cluster_autoscaler          = true` parameter, the cluster-autoscale feature will be activated. This means that, based on the load, the number of instances will automatically adjust within the range of the minimum and maximum values you've set.

Enabling the `enable_aws_load_balancer_controller = true` parameter will set up the load balancer controller and allow you to publish your applications to the internet using ingress.

#### Deploy cluster

To apply terraform, simply run the following commands on your command console.

    cd eks-tf
    terraform init
    terrafrom plan -var-file="example.tfvars"
    terrafrom apply -var-file="example.tfvars"

The installation process may require around 20 minutes. Once the cluster is completed, it is now available for utilization.

## Deploy an applicaton with IRSA
#### Create IRSA role
This Terraform project, called iam-to-pod-roles, shows how to create a pod role. By running this Terraform, you can make a role that provides full access to the specified bucket in the s3_bucket_name_list parameter. The policy that grants this access is outlined in the data.tf file under the resource aws_iam_policy_document.access_to_s3.

Before running Terraform, you must enter the data obtained above in the backend.tf file.

To use this Terraform, you'll need to create a file with parameters, following the example shown in example.tfvars.
Be sure to specify the namespace where your application will run and the name of the ServiceAccount. This information is crucial.

    kubernetes_namespace = "default"
    kubernetes_serviceaccount_name = "my-pod-sa"

To apply terraform, simply run the following commands on your command console.

    cd iam-to-pod-roles
    terraform init
    terrafrom plan -var-file="example.tfvars"
    terrafrom apply -var-file="example.tfvars"

After completing this step, you will have an irsa_role_arn that you can utilize while setting up the Kubernetes ServiceAccount.

#### Configure a Kubernetes ServiceAccount
To link your service account and role, add an annotation `eks.amazonaws.com/role-arn: MY_ROLE_ARN` to the service account manifest.

The complete ServiceAccount manifest will resemble something similar to this.
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-pod-sa
  annotations:
    eks.amazonaws.com/role-arn: MY_ROLE_ARN
```

#### Configure kubectl
Create or update a kubeconfig file for your cluster. Replace `region-code` with the AWS Region that your cluster is in and replace `my-cluster` with the name of your cluster.

    aws eks update-kubeconfig --region region-code --name my-cluster

By default, the resulting configuration file is created at the default kubeconfig path (.kube) in your home directory or merged with an existing config file at that location.

For all available options, run the aws eks update-kubeconfig help command or see update-kubeconfig in the AWS CLI Command Reference.

###### Test your configuration.

    kubectl get svc

An example output is as follows.

    NAME             TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
    svc/kubernetes   ClusterIP   10.100.0.1   <none>        443/TCP   1m
If you receive any authorization or resource type errors, see[ Unauthorized or access denied (kubectl)](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html#unauthorized " Unauthorized or access denied (kubectl)") in the troubleshooting topic.

#### Apply test deployment manifest









