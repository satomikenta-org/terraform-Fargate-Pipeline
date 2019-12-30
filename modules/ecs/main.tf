/*====
Cloudwatch Log Group
======*/
resource "aws_cloudwatch_log_group" "app_log_group" {
  name = "${var.app_name}"

  tags = {
    Environment = "${var.environment}"
    Application = "${var.app_name}"
  }
}

/*====
ECR repository to store our Docker images
======*/
resource "aws_ecr_repository" "ecr_repository" {
  name = "${var.repository_name}"
}

/*====
ECS cluster
======*/
resource "aws_ecs_cluster" "cluster" {
  name = "${var.environment}-ecs-cluster"
}

/*====
ECS task definitions
======*/

/* the task definition for the  app_service */
data "template_file" "app_task" {
  template = "${file("${path.module}/tasks/app_task_definition.json")}"

  vars = {
    image           = "${aws_ecr_repository.ecr_repository.repository_url}"
    app_port        = "${var.app_port}"
    region          = "${var.region}"
    log_group       = "${aws_cloudwatch_log_group.app_log_group.name}"
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.environment}_app"
  container_definitions    = "${data.template_file.app_task.rendered}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "${var.cpu}"
  memory                   = "${var.memory}"
  execution_role_arn       = "${aws_iam_role.ecs_execution_role.arn}"
  task_role_arn            = "${aws_iam_role.ecs_execution_role.arn}"
}

/*====
App Load Balancer
======*/
resource "random_id" "target_group_sufix" {
  byte_length = 2
}

resource "aws_alb_target_group" "alb_target_group" {
  name     = "${var.environment}-alb-target-group-${random_id.target_group_sufix.hex}"
  port     = "${var.app_port}"
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"
  target_type = "ip"

  lifecycle {
    create_before_destroy = true
  }
}

/* security group for ALB */
resource "aws_security_group" "alb_inbound_sg" {
  name        = "${var.environment}-alb-inbound-sg"
  description = "Allow HTTP from Anywhere into ALB"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-alb-inbound-sg"
  }
}

resource "aws_alb" "alb" {
  name            = "${var.environment}-alb"
  subnets         = "${var.public_subnet_ids}"
  security_groups = flatten(["${var.security_groups_ids}", "${aws_security_group.alb_inbound_sg.id}"])
  tags = {
    Name        = "${var.environment}-alb"
    Environment = "${var.environment}"
  }
}

resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = "${aws_alb.alb.arn}"
  port              = "80"
  protocol          = "HTTP"
  depends_on        = ["aws_alb_target_group.alb_target_group"]

  default_action {
    target_group_arn = "${aws_alb_target_group.alb_target_group.arn}"
    type             = "forward"
  }
}

/*
* IAM service role
*/
data "aws_iam_policy_document" "ecs_service_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_role" {
  name               = "ecs_role"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_service_role.json}"
}

data "aws_iam_policy_document" "ecs_service_policy" {
  statement {
    effect = "Allow"
    resources = ["*"]
    actions = [
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "ec2:Describe*",
      "ec2:AuthorizeSecurityGroupIngress"
    ]
  }
}

/* ecs service scheduler role */
resource "aws_iam_role_policy" "ecs_service_role_policy" {
  name   = "ecs_service_role_policy"
  #policy = "${file("${path.module}/policies/ecs-service-role.json")}"
  policy = "${data.aws_iam_policy_document.ecs_service_policy.json}"
  role   = "${aws_iam_role.ecs_role.id}"
}

/* role that the Amazon ECS container agent and the Docker daemon can assume */
resource "aws_iam_role" "ecs_execution_role" {
  name               = "ecs_task_execution_role"
  assume_role_policy = "${file("${path.module}/policies/ecs-task-execution-role.json")}"
}
resource "aws_iam_role_policy" "ecs_execution_role_policy" {
  name   = "ecs_execution_role_policy"
  policy = "${file("${path.module}/policies/ecs-execution-role-policy.json")}"
  role   = "${aws_iam_role.ecs_execution_role.id}"
}

/*====
ECS service
======*/

/* Security Group for ECS */
resource "aws_security_group" "ecs_service" {
  vpc_id      = "${var.vpc_id}"
  name        = "${var.environment}-ecs-service-sg"
  description = "Allow egress from container"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-ecs-service-sg"
    Environment = "${var.environment}"
  }
}

# /* Simply specify the family to find the latest ACTIVE revision in that family */
data "aws_ecs_task_definition" "app" {
   task_definition = "${aws_ecs_task_definition.app.family}"
   depends_on = ["aws_ecs_task_definition.app"]
}



##################### NOTICE #########################

# :ecs_service 
# loadbalancer => target_group_arn cause error at first.
# this is not fixed terraform issue 2019/06/15

######################################################
resource "aws_ecs_service" "app_service" {
  name            = "${var.environment}-app_service"
  task_definition = "${aws_ecs_task_definition.app.family}:${max("${aws_ecs_task_definition.app.revision}", "${data.aws_ecs_task_definition.app.revision}")}"
  desired_count   = "${var.desired_count}"
  launch_type     = "FARGATE"
  cluster =       "${aws_ecs_cluster.cluster.id}"
  depends_on      = ["aws_iam_role_policy.ecs_service_role_policy"]

  network_configuration {
    security_groups = flatten(["${var.security_groups_ids}", "${aws_security_group.ecs_service.id}"])
    subnets         = "${var.subnets_ids}"
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.alb_target_group.arn}"
    container_name   = "app"
    container_port   = "${var.app_port}"
  }
}


/*====
Auto Scaling for ECS
======*/

resource "aws_iam_role" "ecs_autoscale_role" {
  name               = "${var.environment}_ecs_autoscale_role"
  assume_role_policy = "${file("${path.module}/policies/ecs-autoscale-role.json")}"
}
resource "aws_iam_role_policy" "ecs_autoscale_role_policy" {
  name   = "ecs_autoscale_role_policy"
  policy = "${file("${path.module}/policies/ecs-autoscale-role-policy.json")}"
  role   = "${aws_iam_role.ecs_autoscale_role.id}"
}

resource "aws_appautoscaling_target" "target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.app_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = "${aws_iam_role.ecs_autoscale_role.arn}"
  min_capacity       = "${var.desired_count}"
  max_capacity       = "${var.scale_max_count}"
}

resource "aws_appautoscaling_policy" "up" {
  name                    = "${var.environment}_scale_up"
  service_namespace       = "ecs"
  resource_id             = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.app_service.name}"
  scalable_dimension      = "ecs:service:DesiredCount"


  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment = 1
    }
  }

  depends_on = ["aws_appautoscaling_target.target"]
}

resource "aws_appautoscaling_policy" "down" {
  name                    = "${var.environment}_scale_down"
  service_namespace       = "ecs"
  resource_id             = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.app_service.name}"
  scalable_dimension      = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment = -1
    }
  }

  depends_on = ["aws_appautoscaling_target.target"]
}

/* metric used for auto scale up*/
resource "aws_cloudwatch_metric_alarm" "service_cpu_high" {
  alarm_name          = "${var.environment}_app_cpu_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "85"

  dimensions = {
    ClusterName = "${aws_ecs_cluster.cluster.name}"
    ServiceName = "${aws_ecs_service.app_service.name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.up.arn}"]  # if cpuUtilization greater than 85%
  ok_actions    = ["${aws_appautoscaling_policy.down.arn}"] # else === ok => scale down 
}

# /* metric used for auto scale down */
# resource "aws_cloudwatch_metric_alarm" "cpu_utilization_low" {
#   alarm_name          = "${var.environment}_app_cpu_utilization_row"
#   comparison_operator = "LessThanThreshold"
#   evaluation_periods  = "2"
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/ECS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = "10"  # avarage cpu utilization (%) 

#   dimensions {
#     ClusterName = "${aws_ecs_cluster.cluster.name}"
#     ServiceName = "${aws_ecs_service.app_service.name}"
#   }

#   alarm_actions = ["${aws_appautoscaling_policy.down.arn}"]
# }