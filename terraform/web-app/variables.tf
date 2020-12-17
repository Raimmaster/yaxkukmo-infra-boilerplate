variable "vpc" {
  default = ""
}

variable "availability_zones" {
  default = []
}

variable "private_subnets" {
  default = []
}

variable "public_subnets" {
  default = []
}

variable "amount_of_instances" {
  default = 2
}

variable "domain" {
  default = ""
}

variable "jumper_ip" {
  default = ""
}

variable "public_key" {

}