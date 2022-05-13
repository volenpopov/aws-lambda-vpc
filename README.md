# AWS Lambda VPC

This repository contains a best-practice example implementation of a **AWS Lambda function** inside of a **VPC** using **Terraform**.

## Table of contents

- [What's the idea behind this project?](https://github.com/volenpopov/aws-lambda-vpc#whats-the-idea-behind-this-project)
- [How to use/deploy this project?](https://github.com/volenpopov/aws-lambda-vpc#how-to-usedeploy-this-project)
- [Solution Architecture](https://github.com/volenpopov/aws-lambda-vpc#solution-architecture)
- [Explanations](https://github.com/volenpopov/aws-lambda-vpc#explanations)
- [Examples](https://github.com/volenpopov/aws-lambda-vpc#explanations)

## What's the idea behind this project?

This is a demo project that I have implemented with the goal to enhance my practical skills with AWS and Terraform.

## How to use/deploy this project?

- configure AWS access keys for an IAM user with admin rights from your AWS account and also make sure you have AWS CLI working
- clone this repository locally
- comply with the required Terraform, NodeJS and NPM versions
- execute the `scripts/deploy.sh` script
- execute the `scripts/test.sh` script

**If using Windows I strongly recommend that you use WSL, otherwise you will encounter errors/problems which are not covered here. Also when cloning the repository locally make sure it is done through your WSL console.**

## Solution Architecture

![Please refer to the architecture.png file at the root of the repository](https://github.com/volenpopov/aws-lambda-vpc/blob/main/architecture.png?raw=true)

## Explanations

<details>
<summary><b>Lambda</b></summary><p>

- The lambda function downloads an object from S3 whose name is passed in as a parameter to the function and then a simple `SELECT NOW()` query is executed against the RDS database. The purpose of all of this is to show that our function can successfully connect to both S3, RDS and SecretsManager.

- The solution architecture diagram depicts how the AWS Lambda service creates an ENI (Elastic Network Interface) inside the specified subnets of our VPC, in order for the lambda function to have network access to resources within our VPC (such as our RDS database). The lambda function itself is still being hosted and executed on AWS managed infrastructure outside of our VPC. However, now that a Lambda ENI inside of our VPC is being used the lambda function can't connect out of the box to S3 and Secrets Manager, thus a VPC Gateway Endpoint (for S3) and a VPC Interface Endpoint (for Secrets Manager) are created, in order to provide private network access from our VPC to these services.
- Lambda VPC config:
  ![image](https://user-images.githubusercontent.com/34790079/166524532-b54d0af9-0c93-447b-b04b-1944821260cf.png)

</p></details>

<details>
<summary><b>VPC</b></summary><p>

- A VPC CIDR of 10.16.0.0/25 is used, which gives us 8 subnets of size /28 with 9 available IPs for use (14 in total - 5 AWS reserved ones) suiting perfectly our architecture of 5 private subnets (3 compute and 2 database) in 3 AZs (ensuring high availability), also /28 is the minimum size for a subnet in AWS, so we can't reduce it any further. In a real production environment it is NOT recommended to use such a narrow CIDR, because you don't want to loose the ability to expand your custom network when your solution evolves and grows.

- A VPC Gateway Endpoint for private network access from our VPC to S3. The prefix list from the gateway endpoint is referenced in the route table associated with the 3 private compute subnets.
- A VPC Interface Endpoint for private network access from our VPC to Secrets Manager. The interface endpoint works by creating an ENI in the specified subnets, which in our case are the 3 private compute subnets.
- The security groups are using only the bare minimum of rules required for our solution to work and you can also notice that for the Source/Destination fields we are referencing IDs of other security groups or using prefix list IDs, etc.

</p></details>

<details>
<summary><b>S3</b></summary><p>

- The S3 bucket is restricted from public access. Another thing to mention is that by default all identities inside of the AWS account in which the bucket is created are trusted to modify it. In our case we are further restricting access to the bucket by using a resource policy that blocks all access to the bucket from any users different than the account root user, the IAM user used to provision the solution infrastructure and the Lambda function -> [./terraform/policies/bucket-policy.json](./terraform/policies/bucket-policy.json)

</p></details>

<details>
<summary><b>Secrets Manager</b></summary><p>

- Similar to our S3 bucket policy the secret that we use for the database password is only accesible by the account root user, the IAM user used to provision the solution infrastructure and also our Lambda function (which is reduced to only 1 action) -> [./terraform/policies/secrets-policy.json](./terraform/policies/secrets-policy.json)

</p></details>

<details> 
  
<summary><b>RDS</b></summary><p>

- The multi-az option is enabled for high-availability, which gives us a primary and a standby database instance and an automatic failover between them in case of a failure.

- RDS Enhanced Monitoring is enabled and the high CPU Utilization alarm of our database is based on a metric whose values are coming from a metric filter on the enhanced monitoring log data. A much simpler option would be to use the default RDS metrics, however, their data comes from the instance hypervisor while Enhanced Monitoring gathers its metrics from an agent on the virtual machine and thus should be more precise.

</p></details>

## Examples

<details>
  <summary>Cloudwatch Logs output of a successfull lambda invocation</summary>
  
  ![image](https://user-images.githubusercontent.com/34790079/166527758-2774d536-05fb-4acd-8051-95a561192b5f.png)
  ![image](https://user-images.githubusercontent.com/34790079/166538218-042dce3e-2fa7-402d-8f02-171968abefdd.png)
  ![image](https://user-images.githubusercontent.com/34790079/166552036-78e931cf-ad31-4ad4-9909-46077eefd294.png)

</details>

### Thank you and feel free to share!
