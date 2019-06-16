variable "app_name" {
  description = "App Name"
}


variable "repository_url" {
  description = "The url of the ECR repository"
}

variable "codecommit_repo_name" {
  description = "Repository Name of CodeCommit"
}

variable "region" {
  description = "The region to use"
}

variable "ecs_cluster_name" {
  description = "The cluster that we will deploy"
}

variable "task_def_family" {
  description = "task definition family name"
}

variable "ecs_service_name" {
  description = "The ECS service that will be deployed"
}

variable "run_task_subnet_id" {
  description = "The subnet Id where single run task will be executed"
}

variable "run_task_security_group_ids" {
  type        = "list"
  description = "The security group Ids attached where the single run task will be executed"
}