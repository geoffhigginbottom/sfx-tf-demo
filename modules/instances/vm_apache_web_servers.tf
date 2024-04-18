resource "aws_instance" "apache_web" {
  count                     = var.apache_web_count
  ami                       = var.ami
  instance_type             = var.instance_type
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

  ### needed for Splunk Golden Image to enable SSH
  ### the 'ssh connection' should use the same user
  # user_data = file("${path.module}/scripts/userdata.sh")

  tags = {
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
    source      = "${path.module}/scripts/install_splunk_universal_forwarder_apache.sh"
    destination = "/tmp/install_splunk_universal_forwarder_apache.sh"
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
      "sudo mkdir /media/data/logs",
      "sudo mkdir /media/data/logs/otel",

      "TOKEN=${var.access_token}",
      "REALM=${var.realm}",
      "HOSTNAME=${self.tags.Name}",
      "LBURL=${aws_lb.gateway-lb.dns_name}",
   
    ## Install Apache
      "sudo chmod +x /tmp/install_apache_web_server.sh",
      "sudo /tmp/install_apache_web_server.sh",

    ## Install Otel Agent
      "sudo curl -sSL https://dl.signalfx.com/splunk-otel-collector.sh > /tmp/splunk-otel-collector.sh",
      "sudo sh /tmp/splunk-otel-collector.sh --realm ${var.realm}  -- ${var.access_token} --mode agent --without-fluentd",
      "sudo chmod +x /tmp/update_splunk_otel_collector.sh",
      "sudo /tmp/update_splunk_otel_collector.sh $LBURL",
      "sudo mv /etc/otel/collector/agent_config.yaml /etc/otel/collector/agent_config.bak",
      "sudo mv /tmp/apache_web_agent_config.yaml /etc/otel/collector/agent_config.yaml",
      "sudo chown splunk-otel-collector:splunk-otel-collector -R /media/data/logs",
      "sudo systemctl restart splunk-otel-collector",

    ## Generate Vars
      var.splunk_ent_count == "1" ? "UNIVERSAL_FORWARDER_FILENAME=${var.universalforwarder_filename}" : "echo skipping because Splunk Ent is not deployed",
      var.splunk_ent_count == "1" ? "UNIVERSAL_FORWARDER_URL=${var.universalforwarder_url}" : "echo skipping because Splunk Ent is not deployed",
      var.splunk_ent_count == "1" ? "PASSWORD=${random_string.splunk_password.result}" : "echo skipping because Splunk Ent is not deployed",
      var.splunk_ent_count == "1" ? "SPLUNK_IP=${aws_instance.splunk_ent.0.private_ip}" : "echo skipping because Splunk Ent is not deployed",

    ## Write env vars to file (used for debugging)
      var.splunk_ent_count == "1" ? "echo $UNIVERSAL_FORWARDER_FILENAME > /tmp/UNIVERSAL_FORWARDER_FILENAME" : "echo skipping because Splunk Ent is not deployed",
      var.splunk_ent_count == "1" ? "echo $UNIVERSAL_FORWARDER_URL > /tmp/UNIVERSAL_FORWARDER_URL" : "echo skipping because Splunk Ent is not deployed",
      var.splunk_ent_count == "1" ? "echo $PASSWORD > /tmp/UNIVERSAL_FORWARDER_PASSWORD" : "echo skipping because Splunk Ent is not deployed",
      var.splunk_ent_count == "1" ? "echo $SPLUNK_IP > /tmp/SPLUNK_IP" : "echo skipping because Splunk Ent is not deployed",

    ## Install Splunk Universal Forwarder
      "sudo chmod +x /tmp/install_splunk_universal_forwarder_apache.sh",
      var.splunk_ent_count == "1" ? "/tmp/install_splunk_universal_forwarder_apache.sh $UNIVERSAL_FORWARDER_FILENAME $UNIVERSAL_FORWARDER_URL $PASSWORD $SPLUNK_IP" : "echo skipping",
    ]
  }

  connection {
    host = self.public_ip
    port = 22
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