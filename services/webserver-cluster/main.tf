resource "aws_launch_configuration" "democlus" {
  image_id        = "ami-04ea996e7a3e7ad6b"
  instance_type   = "${var.instance_type}"
  security_groups = ["${aws_security_group.demo-sg.id}"]
  user_data       = "${data.template_file.user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user-data.sh")}"

  vars = {
    server_port = "${var.server_port}"
    db_address  = "${data.terraform_remote_state.db.address}"
    db_port     = "${data.terraform_remote_state.db.port}"
  }
}

resource "aws_security_group" "demo-sg" {
  name = "${var.cluster_name}-security-group"

  ingress {
    from_port   = "${var.server_port}"
    to_port     = "${var.server_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "demo-elb-sg" {
  name = "${var.cluster_name}-security-group-elb"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = "${aws_security_group.demo-elb-sg.id}"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_http_outbound" {
  type              = "egress"
  security_group_id = "${aws_security_group.demo-elb-sg.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_autoscaling_group" "demo_asg" {
  launch_configuration = "${aws_launch_configuration.democlus.id}"
  availability_zones   = ["${data.aws_availability_zones.all.names}"]
  load_balancers       = ["${aws_elb.demo_elb.name}"]
  health_check_type    = "ELB"

  min_size = "${var.min_size}"
  max_size = "${var.max_size}"

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-asg-demo"
    propagate_at_launch = true
  }
}

resource "aws_elb" "demo_elb" {
  name               = "${var.cluster_name}-elb"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups    = ["${aws_security_group.demo-elb-sg.id}"]

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "${var.server_port}"
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:${var.server_port}/"
  }
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config {
    bucket = "${var.db_remote_state_bucket}"
    key    = "${var.db_remote_state_key}"
    region = "ap-south-1"
  }
}
