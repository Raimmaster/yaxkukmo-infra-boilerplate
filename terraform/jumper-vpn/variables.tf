variable "public_subnets" {
  default = []
}

variable "private_subnets" {
  default = []
}

variable "vpc" {
  default = ""
}

variable "home_ip" {
  default = "0.0.0.0/0"
}

variable "ssh_key" {
  default = ""
}