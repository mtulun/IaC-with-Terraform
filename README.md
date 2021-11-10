# IaC-with-Terraform
Infrastructure management on AWS using Terraform

## Add your accounts credentials in credentials file
You can have credentials for many diffrent AWS accounts in the same credentials file by using profiles.

By default, the credentials file is stored here:

• On Windows: C:\Users\username\ .aws\credentials

• On Mac/Linux: ~/.aws/credentials

[production]

aws_access_key_id = "<key id of prod account>"
  
aws_secret_access_key = "<secret access key of prod account>"
  

With this script, we will create a web server with a ready infrastructure by using many services.
