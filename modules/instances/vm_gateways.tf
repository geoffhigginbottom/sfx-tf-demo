resource "aws_instance" "gateway" {
  count                     = var.gateway_count
  ami                       = var.ami
  instance_type             = var.gateway_instance_type
  subnet_id                 = "${var.public_subnet_ids[ count.index % length(var.public_subnet_ids) ]}"
  key_name                  = var.key_name
  vpc_security_group_ids    = [aws_security_group.instances_sg.id]

  ### needed for Splunk Golden Image to enable SSH
  ### the 'ssh connection' should use the same user
  # user_data = file("${path.module}/scripts/userdata.sh")


  tags = {
    Name = lower(join("-",[var.environment, "gateway", count.index + 1]))
    Environment = lower(var.environment)
    role = "collector"
    splunkit_environment_type = "non-prd"
    splunkit_data_classification = "public"
  }

  provisioner "file" {
    source      = "${path.module}/config_files/gateway_config.yaml"
    destination = "/tmp/gateway_config.yaml"
  }

  provisioner "remote-exec" {
    inline = [
    # Set Hostname
      "sudo sed -i 's/127.0.0.1.*/127.0.0.1 ${self.tags.Name}.local ${self.tags.Name} localhost/' /etc/hosts",
      "sudo hostnamectl set-hostname ${self.tags.Name}",
      "sudo apt-get update",
      "sudo apt-get upgrade -y",

    ## Install Otel Agent     
      "sudo curl -sSL https://dl.signalfx.com/splunk-otel-collector.sh > /tmp/splunk-otel-collector.sh",
      "sudo sh /tmp/splunk-otel-collector.sh --realm ${var.realm} -- ${var.access_token} --mode gateway",
      ## Move gateway_config.yaml to /etc/otel/collector and update permissions,
      "sudo cp /etc/otel/collector/gateway_config.yaml /etc/otel/collector/gateway_config.bak",
      "sudo cp /tmp/gateway_config.yaml /etc/otel/collector/gateway_config.yaml",
      "sudo chown -R splunk-otel-collector:splunk-otel-collector /etc/otel/collector/gateway_config.yaml",
      "sudo systemctl restart splunk-otel-collector",

    ## Configure motd
      "sudo curl -s https://raw.githubusercontent.com/signalfx/observability-workshop/master/cloud-init/motd -o /etc/motd",
      "sudo chmod -x /etc/update-motd.d/*",
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

output "gateway_details" {
  value =  formatlist(
    "%s, %s", 
    aws_instance.gateway.*.tags.Name,
    aws_instance.gateway.*.public_ip,
  )
}