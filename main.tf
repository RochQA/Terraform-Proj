 provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    region = "us-west-2"  
}

resource "instance" "web-1" {
  ami="${var.ami_name}"
  availability_zone= "us-west-2a"
  instance_type = "t2.micro"
  key_name= "${var.key_name}"
  vpc_security_group_ids=["${security-group.web.id}"]
  subnet_id= "${subnet.public-subnet-in-us-west-2.id}"
  associate_public_ip_address = true
  source_dest_check = false
  tags = {
      Name= "webserver"
  }
  
  provisioner "remote-exec"  {
    

    connection {
      type = "ssh"
      host = "${instance.web-1.public_ip}"
      user = "${var.ssh_user}"
      port = "${var.ssh_port}"
      private_key = "${file(var.priv_key_path)}"
      agent = true
    }
    inline = [
      "sudo yum update -y",
      "sudo yum -y install python-pip",
      "sudo pip install ansible",
    ]   
  }

  provisioner "file"  {
    
    connection {
      type = "ssh"
      host = "${instance.web-1.public_ip}"
      user = "${var.ssh_user}"
      port = "${var.ssh_port}"
      private_key = "${file(var.key_path)}"
      agent = true
    }
    
    source = "~/Documents/QAproject/ansible-stuff/main.yml"
    destination = "~/main.yml"    
  }
    provisioner "remote-exec"  {
    
    connection {
      type = "ssh"
      host = "${instance.web-1.public_ip}"
      user = "${var.ssh_user}"
      port = "${var.ssh_port}"
      private_key = "${file(var.key_path)}"
      agent = true

    }
    
    inline = [
      "ansible-playbook main.yml",
      "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
    ]   
  }
}

resource "vpc" "default-vpc" {
    cidr_block = "${var.vpc_cidr_block}"
    enable_dns_hostnames = true
    
    tags = {
        Name = "terraform-vpc"
    } 
}

resource "subnet" "public-subnet-in-us-west-2" {
    vpc_id = "${vpc.default-vpc.id}"
    cidr_block="${var.public_subnet_cidr}"
    availability_zone = "us-west-2a"

    tags = {
        Name = "my public subnet"
    }
}

resource "internet_gateway" "gateway" {
    vpc_id= "${vpc.default-vpc.id}"
    tags = {
        Name = "gateway"
    } 
}

resource "route_table" "public-subnet-us-west-2" {
    vpc_id= "${vpc.default-vpc.id}"

    route{
        cidr_block="0.0.0.0/0"
        gateway_id = "${internet_gateway.defaultgw.id}"       
    }
    tags = {
            Name = "my public subnet"
        }
}

resource "route_table_association" "ass-table" {
    subnet_id = "${subnet.public-subnet-in-us-west-2.id}"
    route_table_id = "${route_table.public-subnet-in-us-west-2.id}"
}

resource "ebs_volume" "extravolume-1" {
  availability_zone = "${var.availability_zone}"
  size = 10

  tags = {
      Name = "ebs volume"
  }
}

resource "volume_attachment" "ebs_attach" {
    device_name = "/dev/sdp"
    volume_id = "${ebs_volume.extravolume-1.id}"
    instance_id = "${instance.web-1.id}"
}

resource "security-group" "sec_group" {
name = "vpc_web"
description = "Allow incoming"

ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
    }
ingress {
    from_port = 8000
    to_port = 8000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
    }


ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
    }
ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
    }

ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"] 
    }
ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
    }

egress{
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks= ["0.0.0.0/0"]
  }
egress{
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks= ["0.0.0.0/0"]
  }
egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
    }
egress {
    from_port = 8000
    to_port = 8000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
    }
egress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

vpc_id = "${vpc.default-vpc.id}"

tags = {
    Name = "QAWebServerSG"
}
}