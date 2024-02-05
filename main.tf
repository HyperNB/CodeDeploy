terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_iam_role" "codeDeployServiceRole" {
  name = "CodeDeployServiceRole"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "codedeploy.amazonaws.com"
          ]
        },
        "Action" : [
          "sts:AssumeRole"
        ]
      }
    ]
  })

  tags = {
    tag-key = "CodeDeployServiceRole"
  }
}

resource "aws_iam_role" "EC2S3FullAccess" {
  name = "EC2S3FullAccess"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "ec2.amazonaws.com" 
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_full_access_attachment" {
  role       = aws_iam_role.EC2S3FullAccess.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core_attachment" {
  role       = aws_iam_role.EC2S3FullAccess.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_instance" "ec2-env" {
  ami                    = "ami-0c7217cdde317cfec"
  instance_type          = "t2.micro"
  iam_instance_profile   = aws_iam_instance_profile.my_role_profile.name
  vpc_security_group_ids = [aws_security_group.my_security_group.id]

  user_data = <<-EOF
    #cloud-config
    package_upgrade: true
    packages:
      - curl
      - wget
    runcmd:
      - cd ~
      - sudo apt install ruby-full
      - wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
      - chmod +x ./install
      - sudo ./install auto
      - echo "sudo service codedeploy-agent status"
        EOF
  tags = {
    Name = "TEST-environment-ec2"
  }
}

resource "aws_iam_instance_profile" "my_role_profile" {
  name = "EC2S3-profile"
  role = aws_iam_role.EC2S3FullAccess.name
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "coursera"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "coursera"
  }
}

resource "aws_security_group" "my_security_group" {
  name        = "http-ssh"
  description = "Security group allowing HTTP access from anywhere"

  # Inbound rule for HTTP from anywhere:
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#todo 
# Choose Create bucket.
# 

resource "aws_s3_bucket" "s3" {
  bucket = "devops-exercise2-nn-11"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}
