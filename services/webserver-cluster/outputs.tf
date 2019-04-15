output "elb_dns_name" {
  value = "${aws_elb.demo_elb.dns_name}"
}

output "elb_security_group_id" {
  value = "${aws_security_group.demo-elb-sg.id}"
}
