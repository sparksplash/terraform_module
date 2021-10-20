provider "aws" {
    region = var.region
}

resource "aws_vpc" "jhlee_vpc" {
    cidr_block          =   "${var.vpc_cidr}"
    instance_tenancy    =   "default"

    tags    =   {
         name = "jhlee-vpc"
    }
}
//public subnet 2개 만듬
resource "aws_subnet" "jhlee_pub" {
  vpc_id     = "${aws_vpc.jhlee_vpc.id}"
  count = "${length(var.public_subnets)}" // 2 -> list에 2개
  cidr_block = "${var.public_subnets[count.index]}"
  availability_zone =   "${var.region}${var.zone[count.index]}"

  tags = {
    Name = "pub-${var.zone[count.index]}"
  }
}
//private subnet 2개 만듬
resource "aws_subnet" "jhlee_pri" {
    vpc_id     = "${aws_vpc.jhlee_vpc.id}"
    count = "${length(var.public_subnets)}"
    cidr_block = "${var.private_subnets[count.index]}"
    availability_zone =   "${var.region}${var.zone[count.index]}"

  tags = {
    Name = "pri-${var.zone[count.index]}"
  }
}

resource "aws_internet_gateway" "jhlee_ig" {
  vpc_id = "${aws_vpc.jhlee_vpc.id}"

  tags = {
    Name = "jhlee-ig"
  }
}

//pulic routing table
resource "aws_route_table" "jhlee_pubrt" {
  vpc_id = "${aws_vpc.jhlee_vpc.id}"

  route {
    cidr_block = "${var.routetable_cidr}"
    gateway_id = aws_internet_gateway.jhlee_ig.id
  }

  tags = {
    Name = "jhlee-pubrt"
  }
}


//public router association
resource "aws_route_table_association" "jhlee_pub_ass" {
    count = "${length(var.public_subnets)}"
  subnet_id      = aws_subnet.jhlee_pub[count.index].id
  route_table_id = "${aws_route_table.jhlee_pubrt.id}"
}


//nat gateway
resource "aws_eip" "jhlee_nat" {
    count = "${length(var.zone)}"
  vpc      = true
}

resource "aws_nat_gateway" "jhlee_ngw_pri" {

  count = "${length(var.zone)}"

  allocation_id = "${aws_eip.jhlee_nat.*.id[count.index]}"
  subnet_id     = "${aws_subnet.jhlee_pub.*.id[count.index]}"
}

//private routing table
resource "aws_route_table" "jhlee_natrt_pri" {
  vpc_id = "${aws_vpc.jhlee_vpc.id}"
  count = "${length(var.zone)}"

  route {
    cidr_block = "${var.routetable_cidr}"
    nat_gateway_id = "${aws_nat_gateway.jhlee_ngw_pri.*.id[count.index]}"
  }

  tags = {
    Name = "jhleev-natrt-pria"
  }
}


//private routing table association
resource "aws_route_table_association" "jhlee_pri_ass" {

    count = "${length(var.private_subnets)}"

  subnet_id      = "${aws_subnet.jhlee_pri.*.id[count.index]}"
  route_table_id = "${aws_route_table.jhlee_natrt_pri.*.id[count.index]}"
}


//security group
resource "aws_security_group" "jhlee_allow_http" {
  name        = "allow_http"
  description = "Allow http inbound traffic"
  vpc_id      = "${aws_vpc.jhlee_vpc.id}"

  ingress = [
    {
      description      = "HTTP from VPC"
      from_port        = var.http_port
      to_port          = var.http_port
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      security_groups   =   null
      prefix_list_ids   =   null
      self              =   null 
    },
    {
      description      = "SSH from VPC"
      from_port        = var.ssh_port
      to_port          = var.ssh_port
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      security_groups   =   null
      prefix_list_ids   =   null
      self              =   null 
    }
  ]

  egress = [
    {
      description      = "all allow"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      security_groups   =   null
      prefix_list_ids   =   null
      self              =   null
    }
  ]

  tags = {
    Name = "jhlee-allow-http"
  }
}

//db security
resource "aws_security_group" "jhlee_allow_mysql" {
  name        = "allow_mysql"
  description = "Allow mysql inbound traffic"
  vpc_id      = aws_vpc.jhlee_vpc.id

  ingress = [
    {
      description       = "mysql from VPC"
      from_port         = 3306
      to_port           = 3306
      protocol          = "tcp"
      cidr_blocks       = [aws_subnet.jhlee_pri[0].cidr_block,aws_subnet.jhlee_pri[1].cidr_block]
      ipv6_cidr_blocks  = ["::/0"]
      prefix_list_ids   = null
      security_groups   = null
      self              = null
    }
  ]

  egress = [
    {
      description       = "default"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = ["0.0.0.0/0"]
      ipv6_cidr_blocks  = ["::/0"]
      prefix_list_ids   = null
      security_groups   = null
      self              = null
    }
  ]

  tags = {
    Name = "jhlee-allow-rds"
  }
}


//web instance
resource "aws_eip" "jhlee_eip_web"{

   count = "${length(var.zone)}"

    instance             = aws_instance.jhlee_web[count.index].id
 #   instance             = aws_instance.jhlee_web.id
    vpc                  = true
}

resource "aws_instance" "jhlee_web" {
  count = "${length(var.zone)}"

    
  ami                    = var.ami
  instance_type          = var.ec2_type
  key_name               = var.key
  vpc_security_group_ids = [aws_security_group.jhlee_allow_http.id]
  availability_zone      = "${var.region}${var.zone[count.index]}"
  private_ip             = "${var.private_ip[count.index]}"
  subnet_id              = aws_subnet.jhlee_pub[count.index].id
  user_data              = file("./wordpress.sh")
}


//load balancer
resource "aws_lb" "jhlee_lb" {

  name               = "jhlee-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.jhlee_allow_http.id]
  subnets   = [aws_subnet.jhlee_pub[0].id, aws_subnet.jhlee_pub[1].id]
/*
  enable_deletion_protection = true

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    prefix  = "test-lb"
    enabled = true
  }
*/
  tags = {
    Env = "test"
  }
}


//LoadBalancer TargetGroup
resource "aws_lb_target_group" "jhlee_lb_tg" {
  name        = "jhlee-lb-tg"
  port        = var.http_port
  protocol    = "HTTP"
#  target_type = "ip"
  vpc_id      = "${aws_vpc.jhlee_vpc.id}"


    health_check {
      enabled             = true
      healthy_threshold   = 3
      interval            = 5
      matcher             = "200" 
      path                = "/"
      port                = "traffic-port"
      protocol            = "HTTP"
      timeout             = 2
      unhealthy_threshold = 2
    }
}


//LoadBalancer Listener
resource "aws_lb_listener" "jhlee_lb_front" {
  load_balancer_arn = aws_lb.jhlee_lb.arn
  port              = var.http_port
  protocol          = "HTTP"
 # certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"
 # alpn_policy       = "HTTP2Preferred"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.jhlee_lb_tg.arn}"
  }
}

// make ami image
resource "aws_ami_from_instance" "jhlee_web_ami" {
  name               = "web-image"
  source_instance_id = aws_instance.jhlee_web[0].id
}


//Auto Scale
resource "aws_launch_configuration" "jhlee_as_conf" {
  name_prefix   = "jhlee-web-"
  image_id      = aws_ami_from_instance.jhlee_web_ami.id
  instance_type = var.ec2_type
  iam_instance_profile  =   "admin_role"
  security_groups   =   [aws_security_group.jhlee_allow_http.id]
  key_name          =   var.key
  user_data         = file("./install.sh")

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_placement_group" "jhlee_pg" {
  name     = "jhlee-pg"
  strategy = "cluster"
}

resource "aws_autoscaling_group" "jhlee_at_sg" {
  name                      = "jhlee-at-sg"
  max_size                  = var.asg_max_size
  min_size                  = var.asg_min_size
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  #placement_group           = aws_placement_group.jhlee_pg.id
  launch_configuration      = aws_launch_configuration.jhlee_as_conf.name
  vpc_zone_identifier       = [aws_subnet.jhlee_pub[0].id, aws_subnet.jhlee_pub[1].id]
}

resource "aws_autoscaling_attachment" "jhlee_asg_attachment_alb" {
  autoscaling_group_name = aws_autoscaling_group.jhlee_at_sg.id
  alb_target_group_arn   = aws_lb_target_group.jhlee_lb_tg.arn
}

resource "aws_db_subnet_group" "jhlee_database" {
  name = "jhlee_db_subnet_group"
  subnet_ids = [aws_subnet.jhlee_pri[0].id,aws_subnet.jhlee_pri[1].id]
}

resource "aws_db_instance" "jhlee_db" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  name                 = "wordpress"
  username             = "wordpress"
  password             = "It12345!"
  parameter_group_name = "default.mysql5.7"
  
  db_subnet_group_name = aws_db_subnet_group.jhlee_database.id

  vpc_security_group_ids = [aws_security_group.jhlee_allow_mysql.id]

  skip_final_snapshot  = true
  tags = {
      name = "jhlee_db"
  }
 /* 
  depends_on = [
    aws_db_subnet_group.tf_mydb_group
  ]
  */
}