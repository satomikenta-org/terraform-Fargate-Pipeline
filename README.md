# terraform-Fargate-Pipeline
Terraform:  Fargate Auto Deploy by AWS-Pipeline(code commit code build ).

* Pre-Requisite

・Create "CodeCommit Repository" beforehand.

・Push Dockernized app code to master branch.

・modules/ecs/tasks/app_task_definiton.json >> Modify containerPort and hostPort for app_port. 

・$ terraform apply


TODO:
Apply SSL and Domain to ALB.


* change main.tf availability_zonez (for ap-north-east a, d)
* change main.tf terraform backend bucket name and key if needed.
* change modules/code_pipeline/main.tf s3 bucket name if needed.
* change modules/ecs/tasks/app_task_definition.json app_port to match app_port in variables.tf
* add terraform.tfvars if needed.
