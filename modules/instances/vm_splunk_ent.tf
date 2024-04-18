resource "random_string" "lo_connect_password" {
  length           = 12
  special          = false
  # override_special = "@£$"
}

resource "aws_instance" "splunk_ent" {
  count                     = var.splunk_ent_count
  ami                       = var.ami
  instance_type             = var.splunk_ent_inst_type
  subnet_id                 = "${var.public_subnet_ids[ count.index % length(var.public_subnet_ids) ]}"
    root_block_device {
    volume_size = 32
    volume_type = "gp2"
  }
  key_name                  = var.key_name
  vpc_security_group_ids    = [
    aws_security_group.instances_sg.id,
    aws_security_group.splunk_ent_sg.id,
  ]

  ### needed for Splunk Golden Image to enable SSH
  ### the 'ssh connection' should use the same user
  # user_data = file("${path.module}/scripts/userdata.sh")

  tags = {
    Name = lower(join("-",[var.environment, "splunk-enterprise", count.index + 1]))
    Environment = lower(var.environment)
    splunkit_environment_type = "non-prd"
    splunkit_data_classification = "public"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install_splunk_enterprise.sh"
    destination = "/tmp/install_splunk_enterprise.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/certs.sh"
    destination = "/tmp/certs.sh"
  }

    provisioner "file" {
    source      = "${path.module}/config_files/splunkent_agent_config.yaml"
    destination = "/tmp/splunkent_agent_config.yaml"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/update_splunk_otel_collector.sh"
    destination = "/tmp/update_splunk_otel_collector.sh"
  }


  provisioner "file" {
    source      = join("/",[var.splunk_enterprise_files_local_path, var.splunk_enterprise_license_filename])
    destination = "/tmp/${var.splunk_enterprise_license_filename}"
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
      
    ## Create Splunk Ent Vars
      "SPLUNK_PASSWORD=${random_string.splunk_password.result}",
      # "SPLUNK_PASSWORD=${var.splunk_password}",
      "LO_CONNECT_PASSWORD=${random_string.lo_connect_password.result}",
      "SPLUNK_ENT_VERSION=${var.splunk_ent_version}",
      "SPLUNK_FILENAME=${var.splunk_ent_filename}",
      "SPLUNK_ENTERPRISE_LICENSE_FILE=${var.splunk_enterprise_license_filename}",

    ## Write env vars to file (used for debugging)
      "echo $SPLUNK_PASSWORD > /tmp/splunk_password",
      "echo $LO_CONNECT_PASSWORD > /tmp/lo_connect_password",
      "echo $SPLUNK_ENT_VERSION > /tmp/splunk_ent_version",
      "echo $SPLUNK_FILENAME > /tmp/splunk_filename",
      "echo $SPLUNK_ENTERPRISE_LICENSE_FILE > /tmp/splunk_enterprise_license_filename",
      "echo $LBURL > /tmp/lburl",

    ## Install Splunk
      "sudo chmod +x /tmp/install_splunk_enterprise.sh",
      "sudo /tmp/install_splunk_enterprise.sh $SPLUNK_PASSWORD $SPLUNK_ENT_VERSION $SPLUNK_FILENAME $LO_CONNECT_PASSWORD",

    ## install NFR license
      "sudo mkdir /opt/splunk/etc/licenses/enterprise",
      "sudo cp /tmp/${var.splunk_enterprise_license_filename} /opt/splunk/etc/licenses/enterprise/${var.splunk_enterprise_license_filename}.lic",
      "sudo /opt/splunk/bin/splunk restart",

    ## Create Certs
      "sudo chmod +x /tmp/certs.sh",
      "sudo /tmp/certs.sh",
      "sudo cp /opt/splunk/etc/auth/sloccerts/mySplunkWebCert.pem /tmp/mySplunkWebCert.pem",
      "sudo chown ubuntu:ubuntu /tmp/mySplunkWebCert.pem",

    ## Install Otel Agent
      "sudo curl -sSL https://dl.signalfx.com/splunk-otel-collector.sh > /tmp/splunk-otel-collector.sh",
      "sudo sh /tmp/splunk-otel-collector.sh --realm ${var.realm}  -- ${var.access_token} --mode agent",
      "sudo chmod +x /tmp/update_splunk_otel_collector.sh",
      "sudo /tmp/update_splunk_otel_collector.sh $LBURL",
      "sudo mv /etc/otel/collector/agent_config.yaml /etc/otel/collector/agent_config.bak",
      "sudo mv /tmp/splunkent_agent_config.yaml /etc/otel/collector/agent_config.yaml",
      "sudo systemctl restart splunk-otel-collector",
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

# output "splunk_ent_details" {
#   value =  formatlist(
#     "%s, %s", 
#     aws_instance.splunk_ent.*.tags.Name,
#     aws_instance.splunk_ent.*.public_ip,
#   )
# }

# output "splunk_ent_urls" {
#   value =  formatlist(
#     "%s%s:%s", 
#     "http://",
#     aws_instance.splunk_ent.*.public_ip,
#     "8000",
#   )
# }

# output "splunk_password" {
#   value = random_string.splunk_password.result
#   # value = var.splunk_password
# }

output "lo_connect_password" {
  value = random_string.lo_connect_password.result
}

output "splunk_enterprise_private_ip" {
    value =  formatlist(
    "%s, %s",
    aws_instance.splunk_ent.*.tags.Name,
    aws_instance.splunk_ent.*.private_ip,
  )
}