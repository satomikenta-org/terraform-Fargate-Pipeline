module "code_pipeline" {
  source                      = "./modules/code_pipeline"
  repository_url              = "${module.ecs.repository_url}"
  codecommit_repo_name        = "${var.codecommit_repo_name}"
  app_name                    = "${var.app_name}"
  region                      = "${var.region}"
  ecs_service_name            = "${module.ecs.service_name}"
  ecs_cluster_name            = "${module.ecs.cluster_name}"
  task_def_family             = "${module.ecs.task_def_family}"
  run_task_subnet_id          = "${module.networking.private_subnets_id[0]}"
  run_task_security_group_ids = ["${module.networking.security_groups_ids}", "${module.ecs.security_group_id}"]
}
