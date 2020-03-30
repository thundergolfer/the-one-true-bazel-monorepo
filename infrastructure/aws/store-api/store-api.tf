terraform {
  required_version = "0.12.18"
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "domain_name" {
  type = string
}

provider "aws" {
  region = var.region
}

data "terraform_remote_state" "artifacts" {
  backend = "local"
  config = {
    path = "../artifacts/${var.environment}.tfstate"
  }
}

data "aws_partition" "current" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_iam_policy_document" "store_api_trust_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "store_api" {
  name = "store-api"
  assume_role_policy = data.aws_iam_policy_document.store_api_trust_policy.json

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "store_api_permissions" {
  statement {
    actions = [
      "s3:Get*",
      "s3:List*",
    ]

    resources = [
      "${data.terraform_remote_state.artifacts.outputs.artifacts_bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "store_api_permissions" {
  name = "store-api"
  policy = data.aws_iam_policy_document.store_api_permissions.json
}

resource "aws_iam_instance_profile" "store_api" {
  name = "store-api"
  role = aws_iam_role.store_api.name
}

// TODO(Jonathon): Set up security group for this so that I can connect over SSH and any internet browser can connect on port 8080
resource "aws_instance" "store_api" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.nano"
  iam_instance_profile = "store-api"
  key_name = "store-api" // Note: Created outside of Terraform using AWS Console
  user_data = templatefile("${path.module}/userdata.tpl", {})

  tags = {
    Name = "store-api"
  }
}

// Connect traffic to api.antilibrary.xyz to EC2 instance
resource "aws_route53_zone" "main" {
  name = var.domain_name
}


resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [
    aws_instance.store_api.public_ip,
  ]
}
