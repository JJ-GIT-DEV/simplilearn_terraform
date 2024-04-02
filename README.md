### Deploy Infrastructur with terrafrom
====================

This description shows how you can use terraforms to create a infrastructure and install other required automation tools in it on AWS.


1. configuration an service on AWS
1.1 IAM  for create user
![IAM user terraform](image.png)
1.2 Permissions for user and create user
![permissions for user](image-1.png)

1.3 Create access key for user
![create access key](image-2.png)
1.4 Access key for using with command line interface (CLI)
![access key with CLI](image-3.png)
1.5 Store the Access key and Secret access key

2 Connection between develop machine and aws
2.1 aws configure will be store in .aws on profile

3 Resource on AWS on EC2 for ubuntu machine
![AMI ID](image-4.png)

4 Resource file with variable on terraform create a file with variable.tf



# terraform commands
terraform plan -> verify the command 
terrafrom apply -> execute and create
terraform destroy -> delete the infrastructure