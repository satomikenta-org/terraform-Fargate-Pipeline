variable "region" {
  description = "Region that the infrastructure will be created"
}

variable "access_key" {
  description = "aws access_key"
}

variable "secret_key" {
  description = "aws secret_key"
}

variable "environment" {
  description = "Environment: dev or prod"
}

variable "app_name" {
  description = "APP Name"
}


variable "repository_name" {
  description = "ECR repository name"  
}

variable "codecommit_repo_name" {
  description = "CodeCommit repository name"
}


variable "cpu" {
  description = "CPU for each Container: 256 etc"
}

variable "memory" {
  description = "Memory for each Container: 512 etc"
}

variable "app_port" {
  description = "Application Port listening in Container. You need to adjust containerPort hostPort in task_definition.json"
}


variable "desired_count" {
  description = "Desired Count of App Task"
}

variable "scale_max_count" {
  description = "Desired Max Count of App Task for AutoScale"
}
