output "repository_url" {
  value = "${aws_ecr_repository.ecr_repository.repository_url}"
}

output "cluster_name" {
  value = "${aws_ecs_cluster.cluster.name}"
}

output "task_def_family" {
  value = "${aws_ecs_task_definition.app.family}"
}


output "service_name" {
  value = "${aws_ecs_service.app_service.name}"
}

output "alb_dns_name" {
  value = "${aws_alb.alb.dns_name}"
}

output "alb_zone_id" {
  value = "${aws_alb.alb.zone_id}"
}

output "security_group_id" {
  value = "${aws_security_group.ecs_service.id}"
}