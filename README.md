# terraform-Fargate-Pipeline
Terraform:  Fargate Auto Deploy by AWS-Pipeline(code commit code build ).

* Pre-Requisite

・Create "CodeCommit Repository" beforehand.

・Push Dockernized app code to master branch.

・modules/ecs/tasks/app_task_definiton.json >> Modify containerPort and hostPort for app_port. 

・$ terraform apply


TODO:
Apply SSL and Domain to ALB.