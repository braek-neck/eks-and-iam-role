# Terraform to deploy EKS and IRSA
## Description

This project aims to simplify the process of setting up an EKS cluster. Additionally, instructions are provided below on how to create an IRSA role and use it to access an S3 bucket from a pod.

Prerequisites for installation include an AWS EKS cluster. Optional components include a
* [AWS Load Balancer Controller](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html "AWS Load Balancer Controller")
* [Cluster Autoscaler](https://docs.aws.amazon.com/eks/latest/userguide/autoscaling.html "Autoscaler")
* [CloudWatch agent to collect cluster metrics](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-metrics.html "CloudWatch agent to collect cluster metrics")
* [Fluent Bit to send logs to CloudWatch Logs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html "Fluent Bit to send logs to CloudWatch Logs")

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

AWS Load Balancer controller auto discovers network subnets for ALB or NLB by default. ALB requires at least two subnets across Availability Zones, NLB requires one subnet. The subnets must be tagged appropriately for the auto discovery to work. The controller chooses one subnet from each Availability Zone. In case of multiple tagged subnets in an Availability Zone, the controller will choose the first one in lexicographical order by the Subnet IDs.  See [Subnet Auto Discovery](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/deploy/subnet_discovery/ "Subnet Auto Discovery") for more information.

If you are unable to tag the subnets, you can still specify their IDs in the ingress settings.

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

The init-backend command should only be executed once. This Terraform project does not store state remotely, but creates the necessary components for other Terraform projects to store their state remotely.

```
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

After creating an Amazon EKS cluster, the IAM principal responsible for creating the cluster automatically receives system:masters privileges in the role-based access control (RBAC) configuration within the Amazon EKS control plane. However, this principal is not visible in any configuration, so it is important to keep track of which principal created the cluster. To add other IAM principals, you can incorporate a variable value into aws_auth_roles, aws_auth_users, or aws_auth_accounts.

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

If you use Helm, you can pass an additional annotation for the ServiceAccount as a parameter.

```yaml
rbac:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: ROLE_ARN
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
In the deployment.yaml file under pod-example directory, there is an example manifest that creates deployment and ServiceAccount creation with an IAM role attached. The docker image amazon/aws-cli:latest is used to start the container.

Change the role ARN in the deployment.yaml file to match the one obtained in the #create-irsa-role step, and then execute the command.

    kubectl apply -f pod-example/deployment.yaml -n default

In order to verify, execute the following command:

    kubectl get pods -n default

You'll see something like this

    NAME                      READY   STATUS    RESTARTS   AGE
    my-pod-858f56b875-xcbm8   1/1     Running   0          26s

Then you can run some commands to make sure that the role is indeed attached to your pod and you can access the s3 bucket.

    $ kubectl exec my-pod-858f56b875-xcbm8 -n default -- aws sts get-caller-identity
    {
        "UserId": "AROAXC5OGGREHKGRTOWXA:botocore-session-1696255516",
        "Account": "487307228232",
        "Arn": "arn:aws:sts::00000000000:assumed-role/test-pod-role/botocore-session-1696255516"
    }
    
    ~/
    $ kubectl exec my-pod-858f56b875-xcbm8 -n default -- aws s3 ls
    2023-09-27 04:53:42 0000000000-us-east-1-terraform-state
    2022-02-10 15:24:19 drongo-test
    2023-10-01 15:04:30 drongo-test2
    
    ~/ 
    $ kubectl exec my-pod-858f56b875-xcbm8 -n default -- aws s3 ls s3://drongo-test
    2022-02-10 16:34:43      42706 test.txt

You can then delete the role.
Run the following commands.

    kubectl delete -f pod-example/deployment.yaml -n default
and

    cd iam-to-pod-roles
    terrafrom destroy -var-file="example.tfvars"

