resource "aws_instance" "mysql" {
  count                     = var.mysql_count
  ami                       = var.ami
  instance_type             = var.mysql_instance_type
  subnet_id                 = "${var.public_subnet_ids[ count.index % length(var.public_subnet_ids) ]}"
  key_name                  = var.key_name
  vpc_security_group_ids    = [aws_security_group.instances_sg.id]

  ### needed for Splunk Golden Image to enable SSH
  ### the 'ssh connection' should use the same user
  # user_data = file("${path.module}/scripts/userdata.sh") 

  tags = {
    Name = lower(join("-",[var.environment, "mysql", count.index + 1]))
    Environment = lower(var.environment)
    splunkit_environment_type = "non-prd"
    splunkit_data_classification = "public"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install_mysql.sh"
    destination = "/tmp/install_mysql.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/update_splunk_otel_collector_conf_mysql.sh"
    destination = "/tmp/update_splunk_otel_collector_conf_mysql.sh"
  }

  provisioner "file" {
    source      = "${path.module}/config_files/mysql_agent_config.yaml"
    destination = "/tmp/mysql_agent_config.yaml"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install_splunk_universal_forwarder_mysql.sh"
    destination = "/tmp/install_splunk_universal_forwarder_mysql.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i 's/127.0.0.1.*/127.0.0.1 ${self.tags.Name}.local ${self.tags.Name} localhost/' /etc/hosts",
      "sudo hostnamectl set-hostname ${self.tags.Name}",
      "sudo apt-get update",
      "sudo apt-get upgrade -y",

      "TOKEN=${var.access_token}",
      "REALM=${var.realm}",
      "HOSTNAME=${self.tags.Name}",
      "LBURL=${aws_lb.gateway-lb.dns_name}",
      "MYSQLUSER=${var.mysql_user}",
      "MYSQLPWD=${var.mysql_user_pwd}",

    ## Install MySQL
      "sudo chmod +x /tmp/install_mysql.sh",
      "sudo /tmp/install_mysql.sh",
      "sudo mysql -u root -p'root' -e \"CREATE USER 'signalfxagent'@'localhost' IDENTIFIED BY '${var.mysql_user_pwd}';\"",
      "sudo mysql -u root -p'root' -e \"GRANT USAGE ON *.* TO '${var.mysql_user}'@'localhost';\"",
      "sudo mysql -u root -p'root' -e \"GRANT REPLICATION CLIENT ON *.* TO '${var.mysql_user}'@'localhost';\"",
    
    # Install Otel Agent
      "sudo curl -sSL https://dl.signalfx.com/splunk-otel-collector.sh > /tmp/splunk-otel-collector.sh",
      "sudo sh /tmp/splunk-otel-collector.sh --realm ${var.realm}  -- ${var.access_token} --mode agent --without-fluentd",
      "sudo mv /etc/otel/collector/agent_config.yaml /etc/otel/collector/agent_config.bak",
      "sudo mv /tmp/mysql_agent_config.yaml /etc/otel/collector/agent_config.yaml",
      "sudo chmod +x /tmp/update_splunk_otel_collector_conf_mysql.sh",
      "sudo /tmp/update_splunk_otel_collector_conf_mysql.sh $LBURL $MYSQLUSER $MYSQLPWD",

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
      "sudo chmod +x /tmp/install_splunk_universal_forwarder_mysql.sh",
      var.splunk_ent_count == "1" ? "/tmp/install_splunk_universal_forwarder_mysql.sh $UNIVERSAL_FORWARDER_FILENAME $UNIVERSAL_FORWARDER_URL $PASSWORD $SPLUNK_IP" : "echo skipping because Splunk Ent is not deployed",
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

output "mysql_details" {
  value =  formatlist(
    "%s, %s", 
    aws_instance.mysql.*.tags.Name,
    aws_instance.mysql.*.public_ip,
  )
}