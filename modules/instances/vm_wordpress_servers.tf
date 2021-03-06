resource "aws_instance" "wordpress" {
  count                     = var.wordpress_count
  ami                       = var.ami
  instance_type             = var.instance_type
  subnet_id                 = element(var.public_subnet_ids, count.index)
  root_block_device {
    volume_size = 16
    volume_type = "gp2"
  }
  ebs_block_device {
    device_name = "/dev/xvdg"
    volume_size = 8
    volume_type = "gp2"
  }
  key_name                  = var.key_name
  vpc_security_group_ids    = [aws_security_group.instances_sg.id]

  tags = {
    Name = lower(join("_",[var.environment,element(var.wordpress_ids, count.index)]))
  }
 
  provisioner "file" {
    source      = "${path.module}/scripts/install_sfx_agent.sh"
    destination = "/tmp/install_sfx_agent.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/update_signalfx_config.sh"
    destination = "/tmp/update_signalfx_config.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install_apache.sh"
    destination = "/tmp/install_apache.sh"
  }

  provisioner "file" {
    source      = "${path.module}/agents/wordpress.yaml"
    destination = "/tmp/wordpress.yaml"
  }

  provisioner "file" {
    source      = "${path.module}/agents/free_disk.yaml"
    destination = "/tmp/free_disk.yaml"
  }

    provisioner "remote-exec" {
    inline = [
      "sudo sed -i 's/127.0.0.1.*/127.0.0.1 ${self.tags.Name}.local ${self.tags.Name} localhost/' /etc/hosts",
      "sudo hostnamectl set-hostname ${self.tags.Name}",
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      
      "sudo mkdir /media/data",
      "sudo echo 'type=83' | sudo sfdisk /dev/xvdg",
      "sudo mkfs.ext4 /dev/xvdg1",
      "sudo mount /dev/xvdg1 /media/data",

      "TOKEN=${var.access_token}",
      "REALM=${var.realm}",
      "HOSTNAME=${self.tags.Name}",
      "AGENTVERSION=${var.smart_agent_version}",
      "LBURL=${aws_lb.collector-lb.dns_name}",

      "sudo chmod +x /tmp/install_sfx_agent.sh",
      "sudo /tmp/install_sfx_agent.sh $TOKEN $REALM $AGENTVERSION",
      "sudo chmod +x /tmp/update_signalfx_config.sh",
      "sudo /tmp/update_signalfx_config.sh $LBURL",

      "sudo mkdir /etc/signalfx/monitors",
      "sudo mv /tmp/wordpress.yaml /etc/signalfx/monitors/wordpress.yaml",
      "sudo chown root:root /etc/signalfx/monitors/wordpress.yaml",
      "sudo mv /tmp/free_disk.yaml /etc/signalfx/monitors/free_disk.yaml",
      "sudo chown root:root /etc/signalfx/monitors/free_disk.yaml",
      
      "sudo chmod +x /tmp/install_apache.sh",
      "sudo /tmp/install_apache.sh",
    ]
  }

  connection {
    host = self.public_ip
    type = "ssh"
    user = "ubuntu"
    private_key = file(var.private_key_path)
    agent = "true"
  }
}

output "wordpress_details" {
  value =  formatlist(
    "%s, %s", 
    aws_instance.wordpress.*.tags.Name,
    aws_instance.wordpress.*.public_ip,
  )
}