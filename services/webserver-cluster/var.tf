data "aws_availability_zones" "all" {}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default     = 8080
}

variable "cluster_name" {
  description = "The name to use for all the cluster resources"
}

variable "db_remote_state_bucket" {
  description = "remote bucket for TF State"
}

variable "db_remote_state_key" {
  description = "remote bucket key"
}

variable "instance_type" {
  description = "The type of EC2 instance"
}

variable "min_size" {
  description = "The minimum number of EC2 instance"
}

variable "max_size" {
  description = "The maximum number of EC2 instance"
}
