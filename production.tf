/*====
Variables used across all modules
======*/
locals {
  production_availability_zones = ["us-east-2a", "us-east-2b"]
}

provider "aws" {
  region  = "${var.region}"
}


module "networking" {
  source               = "./modules/networking"
  environment          = "production"
  vpc_cidr             = "10.0.0.0/16"
  public_subnets_cidr  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets_cidr = ["10.0.10.0/24", "10.0.20.0/24"]
  region               = "${var.region}"
  availability_zones   = "${local.production_availability_zones}"
  key_name             = "practice" # public key for bustion host
}


module "ecs" {
  source              = "./modules/ecs"
  environment         = "production"
  vpc_id              = "${module.networking.vpc_id}"
  availability_zones  = "${local.production_availability_zones}"
  repository_name     = "satomi/production"
  subnets_ids         = ["${module.networking.private_subnets_id}"]
  public_subnet_ids   = ["${module.networking.public_subnets_id}"]
  security_groups_ids = ["${module.networking.security_groups_ids}"]
}