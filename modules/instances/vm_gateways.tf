resource "aws_instance" "gateway" {
  count                     = var.gateway_count
  ami                       = var.ami
  instance_type             = var.gateway_instance_type
  subnet_id                 = element(var.public_subnet_ids, count.index)
  key_name                  = var.key_name
  vpc_security_group_ids    = [aws_security_group.instances_sg.id]

  tags = {
    Name = lower(join("-",[var.environment,element(var.gateway_ids, count.index)]))
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

    ## Splunk Forwarder
      # "sudo wget -O /tmp/splunkforwarder-8.1.2-545206cc9f70-Linux-x86_64.tgz 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=8.1.2&product=universalforwarder&filename=splunkforwarder-8.1.2-545206cc9f70-Linux-x86_64.tgz&wget=true'",
      # "sudo tar -zxvf /tmp/splunkforwarder-8.1.2-545206cc9f70-Linux-x86_64.tgz -C /opt",
      # "sudo /opt/splunkforwarder/bin/splunk cmd splunkd rest --noauth POST /services/authentication/users 'name=admin&password=password&roles=admin'",
      # "sudo /opt/splunkforwarder/bin/splunk start --accept-license",
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

output "gateway_details" {
  value =  formatlist(
    "%s, %s", 
    aws_instance.gateway.*.tags.Name,
    aws_instance.gateway.*.public_ip,
  )
}