variable region {
  type        = string
#  default     = "ap-northeast-3"
  
}

variable vpc_cidr{
    type = string
 #   default = "10.2.0.0/16"
}
variable public_subnets{
  type = list
 # default = ["10.2.0.0/24", "10.2.2.0/24"]

}
variable private_subnets{
  type = list
 # default = ["10.2.1.0/24", "10.2.3.0/24"]

}

variable zone {
  type = list
#  default = ["a", "c"]
}

variable routetable_cidr{
  type = string
#  default = ["0.0.0.0/0"]
}

variable private_ip{
  type = list
#  default = ["10.2.0.11","10.2.2.11"]
}

variable http_port{
  type = number
  #default = 80
}

variable ssh_port{
  type = number
  #default = 22
}

variable ami{
  type = string
 # default = "ami-0791d2e614355a9eb"
}

variable ec2_type{
  type = string
#  default = "t2.micro"
}

variable key{
  type = string
}

variable asg_max_size{
  type = number
}

variable asg_min_size{
  type = number
}