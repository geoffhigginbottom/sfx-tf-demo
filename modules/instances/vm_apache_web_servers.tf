resource "random_string" "apache_universalforwarder_password" {
  length           = 12
  special          = false
}

resource "aws_instance" "apache_web" {
  count                     = var.apache_web_count
  ami                       = var.ami
  instance_type             = var.instance_type
  # subnet_id                 = element(var.public_subnet_ids, count.index)
  subnet_id                 = "${var.public_subnet_ids[ count.index % length(var.public_subnet_ids) ]}"
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

  user_data = file("${path.module}/scripts/userdata.sh")

  tags = {
    # Name = lower(join("-",[var.environment,element(var.apache_web_ids, count.index)]))
    Name = lower(join("-",[var.environment, "apache", count.index + 1]))
    Environment = lower(var.environment)
    splunkit_environment_type = "non-prd"
    splunkit_data_classification = "public"
  }
 
  provisioner "file" {
    source      = "${path.module}/scripts/install_apache_web_server.sh"
    destination = "/tmp/install_apache_web_server.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/update_splunk_otel_collector.sh"
    destination = "/tmp/update_splunk_otel_collector.sh"
  }

  provisioner "file" {
    source      = "${path.module}/config_files/apache_web_agent_config.yaml"
    destination = "/tmp/apache_web_agent_config.yaml"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install_splunk_universal_forwarder.sh"
    destination = "/tmp/install_splunk_universal_forwarder.sh"
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
      "LBURL=${aws_lb.gateway-lb.dns_name}",
   
    ## Install Apache
      "sudo chmod +x /tmp/install_apache_web_server.sh",
      "sudo /tmp/install_apache_web_server.sh",

    ## Install Otel Agent
      "sudo curl -sSL https://dl.signalfx.com/splunk-otel-collector.sh > /tmp/splunk-otel-collector.sh",
      # var.splunk_ent_count == "1" ? "sudo sh /tmp/splunk-otel-collector.sh --realm ${var.realm}  -- ${var.access_token} --mode agent --without-fluentd" : "sudo sh /tmp/splunk-otel-collector.sh --realm ${var.realm}  -- ${var.access_token} --mode agent",
      "sudo sh /tmp/splunk-otel-collector.sh --realm ${var.realm}  -- ${var.access_token} --mode agent --without-fluentd",
      "sudo chmod +x /tmp/update_splunk_otel_collector.sh",
      "sudo /tmp/update_splunk_otel_collector.sh $LBURL",
      "sudo mv /etc/otel/collector/agent_config.yaml /etc/otel/collector/agent_config.bak",
      "sudo mv /tmp/apache_web_agent_config.yaml /etc/otel/collector/agent_config.yaml",
      "sudo systemctl restart splunk-otel-collector",

    ## Generate Vars
      "UNIVERSAL_FORWARDER_FILENAME=${var.universalforwarder_filename}",
      "UNIVERSAL_FORWARDER_URL=${var.universalforwarder_url}",
      "PASSWORD=${random_string.apache_universalforwarder_password.result}",
      var.splunk_ent_count == "1" ? "SPLUNK_IP=${aws_instance.splunk_ent.0.private_ip}" : "echo skipping",

    ## Write env vars to file (used for debugging)
      "echo $UNIVERSAL_FORWARDER_FILENAME > /tmp/UNIVERSAL_FORWARDER_FILENAME",
      "echo $UNIVERSAL_FORWARDER_URL > /tmp/UNIVERSAL_FORWARDER_URL",
      "echo $PASSWORD > /tmp/PASSWORD",
      var.splunk_ent_count == "1" ? "echo $SPLUNK_IP > /tmp/SPLUNK_IP" : "echo skipping",

    ## Install Splunk Universal Forwarder
      "sudo chmod +x /tmp/install_splunk_universal_forwarder.sh",
      var.splunk_ent_count == "1" ? "/tmp/install_splunk_universal_forwarder.sh $UNIVERSAL_FORWARDER_FILENAME $UNIVERSAL_FORWARDER_URL $PASSWORD $SPLUNK_IP" : "echo skipping",
      # "sudo /tmp/install_splunk_universal_forwarder.sh $UNIVERSAL_FORWARDER_FILENAME $UNIVERSAL_FORWARDER_URL $PASSWORD $SPLUNK_IP"
    ]
  }

  connection {
    host = self.public_ip
    port = 2222
    type = "ssh"
    user = "ubuntu"
    private_key = file(var.private_key_path)
    agent = "true"
  }
}

output "apache_web_details" {
  value =  formatlist(
    "%s, %s", 
    aws_instance.apache_web.*.tags.Name,
    aws_instance.apache_web.*.public_ip,
  )
}