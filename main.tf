/*====
Variables used across all modules
======*/
locals {
  availability_zones = ["${var.region}a", "${var.region}b"]
}

provider "aws" {
  region  = "${var.region}"
}


module "networking" {
  source               = "./modules/networking"
  environment          = "${var.environment}"
  vpc_cidr             = "10.0.0.0/16"
  public_subnets_cidr  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets_cidr = ["10.0.10.0/24", "10.0.20.0/24"]
  region               = "${var.region}"
  availability_zones   = "${local.availability_zones}"
 # key_name             = "practice" # public key for bustion host
}


module "ecs" {
  source              = "./modules/ecs"
  environment         = "${var.environment}"
  app_name            = "${var.app_name}"
  region              = "${var.region}"  # cloudwatch region
  vpc_id              = "${module.networking.vpc_id}"
  availability_zones  = "${local.production_availability_zones}"
  repository_name     = "${var.repository_name}"
  subnets_ids         = ["${module.networking.private_subnets_id}"]
  public_subnet_ids   = ["${module.networking.public_subnets_id}"]
  security_groups_ids = ["${module.networking.security_groups_ids}"]
  app_port            = "${var.app_port}"
  desired_count       = "${var.desired_count}"
  scale_max_count     = "${var.scale_max_count}"
  cpu                 = "${var.cpu}"
  memory              = "${var.memory}"
}