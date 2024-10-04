# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure AWS Region
provider "aws" {
  region = "eu-west-1" # Replace with your desired region
}

# Define a variable for the instance type (default to t2.micro)
variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  default = "admin"
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.ssh.public_key_openssh
}

output "private_key" {
  value     = tls_private_key.ssh.private_key_pem
  sensitive = true
}


data "aws_ami" "debian" {
  most_recent = true

  filter {
    name   = "name"
    values = ["student-lab-debian-12-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["021836555818"] # newpush
}


module "container-server" {
  source  = "./modules/container-server"

  # domain = "${format("%s.%s",aws_instance.example.public_ip,".traefik.me")}" 
  domain = "" 

  email  = "lracz@newpush.com"

  files = [
    {
      filename = "docker-compose.portainer.yaml"
      content  = filebase64("./services/docker-compose.portainer.yaml")
    },
    {
      filename = "docker-compose.watchtower.yaml"
      content  = filebase64("./services/docker-compose.watchtower.yaml")
    },
    {
      filename = "docker-compose.traefik.yaml"
      content  = filebase64("./services/docker-compose.traefik.yaml")
    },
    {
      filename = "docker-compose.whoami.yaml"
      content  = filebase64("./services/docker-compose.whoami.yaml")
    },
    {
      filename = "docker-compose.kali.yaml"
      content  = filebase64("./services/docker-compose.kali.yaml")
    },
    {
      filename = "docker-compose.guacamole.yaml"
      content  = filebase64("./services/docker-compose.guacamole.yaml")
    },
    {
      filename = "docker-compose.mafl.yaml"
      content  = filebase64("./services/docker-compose.mafl.yaml")
    },
    {
      filename = "mafl/config.yml"
      content  = filebase64("./services/mafl/config.yml")
    },
    {
      filename = "traefik/traefik.yml"
      content  = filebase64("./services/traefik/traefik.yml")
    },
  ]

  env = {
    PORTAINER_PASSWORD    = "foobar"
    TRAEFIK_API_DASHBOARD = true
  }

  # extra cloud-init config
  cloudinit_part = [{
    content_type = "text/cloud-config"
    content      = <<EOT
#cloud-config

runcmd:
  - echo "" >> /var/app/.env && echo "DOMAIN=$(curl ifconfig.me).traefik.me" >> /var/app/.env 
  - sleep 60 && set -o allexport && source /var/app/.env && set +o allexport && sed -i "s/DOMAIN/$DOMAIN/g" /var/app/mafl/config.yml
  - systemctl daemon-reload && systemctl enable --now portainer traefik watchtower whoami mafl guacamole kali
EOT
  }]

}

# Launch an EC2 Instance
resource "aws_instance" "example" {
  ami           = data.aws_ami.debian.id
  instance_type = var.instance_type

  # Security group (replace with your own security group ID)
  vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.allow_www.id] 

  # Key pair (replace with your existing key pair name)
  key_name      = aws_key_pair.generated_key.key_name

  user_data_base64 = base64gzip(module.container-server.cloud_config) # 👈

  root_block_device {
    volume_size = 30  # Size in gigabytes (GB)
    volume_type = "gp2" # Optional: Specify volume type, defaults to gp2
  }

  tags = {
    Name = "Student Lab - Scanners EC2 Instance"
  }

}

resource "local_sensitive_file" "pem_file" {
  filename = pathexpand("./.ssh/${var.key_name}.pem")
  file_permission = "600"
  directory_permission = "700"
  content = tls_private_key.ssh.private_key_pem
}

output "public_ip" {
  value = aws_instance.example.public_ip
}
output "traefik_admin_url" {
  value = "${format("https://traefik.%s.%s",aws_instance.example.public_ip,"traefik.me")}" 
}
output "cloud_config" {
  value = module.container-server.cloud_config
}
# Create a Security Group that allows SSH access
resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  description = "Allow SSH traffic"

 ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to the world for this example -  **NOT RECOMMENDED for production**
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

  # Create a Security Group that allows WWW access for port 80, 443, 9080
resource "aws_security_group" "allow_www" {
  name = "allow_www"
  description = "Allow WWW traffic"

 ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to the world for this example -  **NOT RECOMMENDED for production**
  }

 ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to the world for this example -  **NOT RECOMMENDED for production**
  }

 ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to the world for this example -  **NOT RECOMMENDED for production**
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}