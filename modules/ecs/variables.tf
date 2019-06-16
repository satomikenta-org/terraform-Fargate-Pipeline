variable "environment" {
  description = "The environment"
}

variable "region" {
  description = "CloudWatch region"
}

variable "app_name" {
  description = "CloudWatch App name"
}


variable "vpc_id" {
  description = "The VPC id"
}

variable "availability_zones" {
  type        = "list"
  description = "The azs to use"
}

variable "security_groups_ids" {
  type        = "list"
  description = "The SGs to use"
}

variable "subnets_ids" {
  type        = "list"
  description = "The private subnets to use"
}

variable "public_subnet_ids" {
  type        = "list"
  description = "The private subnets to use"
}

variable "repository_name" {
  description = "The name of the repisitory"
}

variable "app_port" {
  description = "Application Port listening in container."
}

variable "cpu" {
  description = "cpu for each container."
}

variable "memory" {
  description = "memory for each container."
}

variable "desired_count" {
  description = "Desired count of App task."
}

variable "scale_max_count" {
  description = "Desired Max count of App task for Autoscale."
}


