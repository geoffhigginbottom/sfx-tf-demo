resource "random_string" "splunk_itsi_password" {
  length           = 12
  special          = false
  # override_special = "@£$"
}

resource "aws_instance" "splunk_itsi" {
  count                     = var.splunk_itsi_count
  ami                       = var.ami
  instance_type             = var.splunk_itsi_inst_type
  subnet_id                 = element(var.public_subnet_ids, count.index)
    root_block_device {
    volume_size = 32
    volume_type = "gp2"
  }
  key_name                  = var.key_name
  vpc_security_group_ids    = [
    aws_security_group.itsi_sg.id
  ]

  tags = {
    Name = lower(join("-",[var.environment,element(var.splunk_itsi_ids, count.index)]))
  }

  provisioner "file" {
    source      = join("/",[var.splunk_itsi_files_local_path, var.splunk_itsi_filename])
    destination = "/tmp/${var.splunk_itsi_filename}"
  }

  provisioner "file" {
    source      = join("/",[var.splunk_itsi_files_local_path, var.splunk_itsi_license_filename])
    destination = "/tmp/${var.splunk_itsi_license_filename}"
  }

  provisioner "file" {
    source      = join("/",[var.splunk_itsi_files_local_path, var.splunk_app_for_content_packs_filename])
    destination = "/tmp/${var.splunk_app_for_content_packs_filename}"
  }

  provisioner "file" {
    source      = join("/",[var.splunk_itsi_files_local_path, var.splunk_it_service_intelligence_filename])
    destination = "/tmp/${var.splunk_it_service_intelligence_filename}"
  }

  provisioner "file" {
    source      = join("/",[var.splunk_itsi_files_local_path, var.splunk_synthetic_monitoring_add_on_filename])
    destination = "/tmp/${var.splunk_synthetic_monitoring_add_on_filename}"
  }

  provisioner "file" {
    source      = join("/",[var.splunk_itsi_files_local_path, var.splunk_infrastructure_monitoring_add_on_filename])
    destination = "/tmp/${var.splunk_infrastructure_monitoring_add_on_filename}"
  }

  provisioner "file" {
    source      = "${path.module}/config_files/inputs.conf"
    destination = "/tmp/inputs.conf"
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
      
    ## Create Splunk Ent Vars
      "SPLUNK_ITSI_PASSWORD=${random_string.splunk_itsi_password.result}",
      "SPLUNK_ITSI_VERSION=${var.splunk_itsi_version}",
      "SPLUNK_ITSI_FILENAME=${var.splunk_itsi_filename}",
      "SPLUNK_ITSI_LICENSE_FILE=${var.splunk_itsi_license_filename}",
      "SPLUNK_IT_SERVICE_INTELLIGENCE_FILENAME=${var.splunk_it_service_intelligence_filename}",
      "SPLUNK_INFRASTRUCTURE_MONITORING_ADD_ON_FILENAME=${var.splunk_infrastructure_monitoring_add_on_filename}",
      "SPLUNK_SYNTHETICS_ADD_ON_FILENAME=${var.splunk_synthetic_monitoring_add_on_filename}",
      "SPLUNK_APP_FOR_CONTENT_PACKS_FILENAME=${var.splunk_app_for_content_packs_filename}",

    ## Write env vars to file (used for debugging)
      "echo $SPLUNK_ITSI_PASSWORD > /tmp/splunk_itsi_password",
      "echo $SPLUNK_ITSI_VERSION > /tmp/splunk_itsi_version",
      "echo $SPLUNK_ITSI_FILENAME > /tmp/splunk_itsi_filename",
      "echo $SPLUNK_ITSI_LICENSE_FILE > /tmp/splunk_itsi_license_file",

    ## Install Splunk Enterprise
      "sudo dpkg -i /tmp/$SPLUNK_ITSI_FILENAME",
      "sudo /opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd $SPLUNK_ITSI_PASSWORD",
      "sudo /opt/splunk/bin/splunk enable boot-start",

    ## install ITSI NFR license
      "sudo mkdir /opt/splunk/etc/licenses/enterprise",
      "sudo cp /tmp/${var.splunk_itsi_license_filename} /opt/splunk/etc/licenses/enterprise/${var.splunk_itsi_license_filename}.lic",
      "sudo /opt/splunk/bin/splunk restart",
    
    ## install java
      "sudo apt install -y default-jre",
      "JAVA_HOME=$(realpath /usr/bin/java)",

    ## stop splunk
      "sudo /opt/splunk/bin/splunk stop",

    ## install apps
      "sudo tar -xvf /tmp/$SPLUNK_IT_SERVICE_INTELLIGENCE_FILENAME -C /opt/splunk/etc/apps",
      "sudo tar -xvf /tmp/$SPLUNK_INFRASTRUCTURE_MONITORING_ADD_ON_FILENAME -C /opt/splunk/etc/apps",
      "sudo tar -xvf /tmp/$SPLUNK_SYNTHETICS_ADD_ON_FILENAME -C /opt/splunk/etc/apps",
      "sudo tar -xvf /tmp/$SPLUNK_APP_FOR_CONTENT_PACKS_FILENAME -C /opt/splunk/etc/apps",

    ## start splunk
      "sudo /opt/splunk/bin/splunk start",

    ## ensure inputs.conf reflects in the UI
      "sudo chmod 755 -R /opt/splunk/etc/apps/itsi/local",

    ## Add Modular Input
      "sudo cp /opt/splunk/etc/apps/itsi/local/inputs.conf /opt/splunk/etc/apps/itsi/local/inputs.bak",
      "sudo cat /tmp/inputs.conf >> /opt/splunk/etc/apps/itsi/local/inputs.conf",

    ## ensure rights are given for the content pack
      "sudo chown splunk:splunk -R /opt/splunk/etc/apps",

    ## restart splunk
      "sudo /opt/splunk/bin/splunk restart"
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

output "splunk_itsi_details" {
  value =  formatlist(
    "%s, %s", 
    aws_instance.splunk_itsi.*.tags.Name,
    aws_instance.splunk_itsi.*.public_ip,
  )
}

output "splunk_itsi_urls" {
  value =  formatlist(
    "%s%s:%s", 
    "http://",
    aws_instance.splunk_itsi.*.public_ip,
    "8000",
  )
}

output "splunk_itsi_password" {
  value = random_string.splunk_itsi_password.result
}
