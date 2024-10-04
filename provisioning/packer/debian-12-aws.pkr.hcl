packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "region" {
    type = string
    default = "eu-west-1"
}

variable "instance-type" {
    type = string
    default = "t1.micro"
}

variable "ssh-username" {
    type = string
    default = "admin"
}

variable "aws-access-key" {
    type = string
}

variable "aws-secret-key" {
    type = string
}

source "amazon-ebs" "debian-12" {
  ami_name      = "student-lab-debian-12-${regex_replace(timestamp(), "[^a-zA-Z0-9-]", "")}"
  instance_type = var.instance-type
  region        = var.region
  ssh_username  = var.ssh-username
  user  = var.ssh-username
  access_key = var.aws-access-key
  secret_key = var.aws-secret-key
  source_ami_filter {
    filters = {
      name                = "debian-12-amd64-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners = ["136693071363"]
  }
  associate_public_ip_address = true
}

build {
  name    = "student-lab-debian-12"
  sources = ["source.amazon-ebs.debian-12"]

    provisioner "shell" {
        inline = [
            "sudo apt-get update",
            "sudo apt-get install -y cloud-init",
            "sudo systemctl enable cloud-init"
        ]
    }

    provisioner "file" {
        source      = "cloud.cfg"
        destination = "/tmp/cloud.cfg"
    }

    provisioner "shell" {
        inline = [
            "sudo mv /tmp/cloud.cfg /etc/cloud/cloud.cfg",
            "sudo chown root:root /etc/cloud/cloud.cfg",
            "sudo chmod 644 /etc/cloud/cloud.cfg"
        ]
    }

    provisioner "shell" {
        inline = [
            "echo 'cloud-init installation and configuration completed'"
        ]
    }
}