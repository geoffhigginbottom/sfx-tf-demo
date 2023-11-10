resource "random_string" "splunk_password" {
  length           = 12
  special          = false
  # override_special = "@£$"
}

resource "random_string" "lo_connect_password" {
  length           = 12
  special          = false
  # override_special = "@£$"
}

resource "aws_instance" "splunk_ent" {
  count                     = var.splunk_ent_count
  ami                       = var.ami
  instance_type             = var.splunk_ent_inst_type
  subnet_id                 = element(var.public_subnet_ids, count.index)
    root_block_device {
    volume_size = 32
    volume_type = "gp2"
  }
  key_name                  = var.key_name
  vpc_security_group_ids    = [
    aws_security_group.instances_sg.id,
    aws_security_group.splunk_ent_sg.id,
  ]

  tags = {
    Name = lower(join("-",[var.environment,element(var.splunk_ent_ids, count.index)]))
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
    type = "ssh"
    user = "ubuntu"
    private_key = file(var.private_key_path)
    agent = "true"
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.splunk_ent[0].id
  public_ip = "13.36.136.240"
}

# resource "splunk_indexes" "otel_k8s" {
#   name                   = "otel-k8s"
#   max_total_data_size_mb = 100000
#   depends_on = [ aws_instance.splunk_ent ]
# }

# resource "splunk_indexes" "otel" {
#   name                   = "otel"
#   max_total_data_size_mb = 100000
#   depends_on = [ aws_instance.splunk_ent ]
# }

# resource "splunk_global_http_event_collector" "http" {
#   disabled   = false
#   enable_ssl = false
#   port       = 8088
#   depends_on = [ aws_instance.splunk_ent ]
# }

# resource "splunk_inputs_http_event_collector" "otel_k8s" {
#   name       = "otel-k8s"
#   index      = "otel-k8s"
#   indexes    = ["otel-k8s"]
#   disabled   = false
#   depends_on = [ aws_instance.splunk_ent ]
# }

# resource "splunk_inputs_http_event_collector" "otel" {
#   name       = "otel"
#   index      = "otel"
#   indexes    = ["otel"]
#   disabled   = false
#   depends_on = [ aws_instance.splunk_ent ]
# }

# resource "splunk_authorization_roles" "lo_connect_role" {
#   name           = "lo-connect-role"
#   imported_roles = ["user"]
#   capabilities   = ["edit_tokens_own"]
#   search_indexes_allowed = ["*"]
#   search_indexes_default = ["main"]
#   search_time_win = "2592000"
#   search_jobs_quota = "12"
#   realtime_search_jobs_quota = "0"
#   cumulative_search_jobs_quota = "12"
#   cumulative_realtime_search_jobs_quota = "0"
#   search_disk_quota = "100"
#   depends_on = [ aws_instance.splunk_ent ]
# }

# resource "splunk_authentication_users" "lo_connect_user" {
#   name              = "lo-connect"
#   password          = random_string.lo_connect_password.result
#   force_change_pass = false
#   roles             = ["lo-connect-role"]
#   depends_on = [ splunk_authorization_roles.lo_connect_role ]
# }

# resource "null_resource" "get_cert" {
#   provisioner "local-exec" {
#     # command = "scp ubuntu@${splunk_enterprise_private_ip}:/tmp/mySplunkWebCert.pem ~/mySplunkWebCert.pem"
#     command = "scp ubuntu@13.36.136.240:/tmp/mySplunkWebCert.pem ~/mySplunkWebCert.pem"
#   }
#   provisioner "local-exec" {
#     when    = destroy
#     command = "~/mySplunkWebCert.pem"
#   }
#   depends_on = [ aws_instance.splunk_ent ]
# }

# resource "null_resource" "get_cert_details" {
#   provisioner "local-exec" {
#     command = "echo ~/mySplunkWebCert.pem"
#   }
#   provisioner "local-exec" {
#     when    = destroy
#     command = "~/mySplunkWebCert.pem"
#   }
# }

# output "splunk_loc_cert"{
#   value = null_resource.get_cert_details
# }

output "splunk_ent_details" {
  value =  formatlist(
    "%s, %s", 
    aws_instance.splunk_ent.*.tags.Name,
    aws_instance.splunk_ent.*.public_ip,
  )
}

output "splunk_ent_urls" {
  value =  formatlist(
    "%s%s:%s", 
    "http://",
    aws_instance.splunk_ent.*.public_ip,
    "8000",
  )
}

output "splunk_password" {
  value = random_string.splunk_password.result
  # value = var.splunk_password
}

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