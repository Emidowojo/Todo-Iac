resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  
  tags = {
    Name = "todo-app-server"
  }

  provisioner "remote-exec" {
    inline = ["echo 'Server is ready!'"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = self.public_ip
    }
  }
  
  provisioner "local-exec" {
    command = "echo '[app_servers]\\n${self.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${var.ssh_private_key_path}' > ../ansible/inventory.yml"
  }
  
  provisioner "local-exec" {
    command = "cd ../ansible && ansible-playbook -i inventory.yml site.yml -e 'app_repo_url=${var.app_repo_url} domain_name=${var.domain_name}'"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  
  owners = ["099720109477"] # Canonical
}