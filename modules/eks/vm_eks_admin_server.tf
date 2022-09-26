resource "aws_instance" "eks_admin_server" {
  ami                       = var.ami
  instance_type             = var.instance_type
  subnet_id                 = element(var.public_subnet_ids, 0)
  key_name                  = var.key_name
  vpc_security_group_ids    = [
    aws_security_group.eks_admin_server.id,
  ]
 
  tags = {
    Name = "${var.environment}_eks_admin"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/generate_aws_config.sh"
    destination = "/tmp/generate_aws_config.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/generate_values.sh"
    destination = "/tmp/generate_values.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install_eks_tools.sh"
    destination = "/tmp/install_eks_tools.sh"
  }

  provisioner "file" {
    source      = "${path.module}/config_files/deployment.yaml"
    destination = "/home/ubuntu/deployment.yaml"
  }

  depends_on = [aws_eks_cluster.demo]

# remote-exec
  provisioner "remote-exec" {
    inline = [
    ## Set Hostname
      "sudo sed -i 's/127.0.0.1.*/127.0.0.1 ${self.tags.Name}.local ${self.tags.Name} localhost/' /etc/hosts",
      "sudo hostnamectl set-hostname ${self.tags.Name}",
      
    ## Update
      "sudo apt-get update",
      "sudo apt-get upgrade -y",

    ## Install Otel Agent
      "sudo curl -sSL https://dl.signalfx.com/splunk-otel-collector.sh > /tmp/splunk-otel-collector.sh",
      "sudo sh /tmp/splunk-otel-collector.sh --realm ${var.realm}  -- ${var.access_token} --mode agent --without-fluentd",

    ## Setup AWS Cli
      "sudo curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip",
      "sudo apt install unzip -y",
      "unzip /tmp/awscliv2.zip",
      "sudo ~/aws/install",
      "sudo chmod +x /tmp/generate_aws_config.sh",
      "AWS_ACCESS_KEY_ID=${var.aws_access_key_id}",
      "AWS_SECRET_ACCESS_KEY=${var.aws_secret_access_key}",
      "REGION=${var.region}",
      "/tmp/generate_aws_config.sh $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY $REGION",

    ## Install EKS Tools
      "sudo chmod +x /tmp/install_eks_tools.sh",
      "/tmp/install_eks_tools.sh",
      "ENVIRONMENT=${var.environment}",
      "sudo chmod +x /tmp/generate_values.sh",
      "/tmp/generate_values.sh $ENVIRONMENT",

    ## Setup eksutils
      "AWS_DEFAULT_REGION=${var.region}",
      "AWS_DEFAULT_OUTPUT=json",
      "EKS_CLUSTER_NAME=${var.eks_cluster_name}",
      "eksctl utils write-kubeconfig --cluster=$EKS_CLUSTER_NAME",
      "eksctl get clusters",
      "aws eks update-kubeconfig --name $EKS_CLUSTER_NAME",

    ## Install K8S Integration using OTEL
      "TOKEN=${var.access_token}",
      "REALM=${var.realm}",
      "EKS_CLUSTER_NAME=${var.eks_cluster_name}",
      "helm repo add splunk-otel-collector-chart https://signalfx.github.io/splunk-otel-collector-chart",
      "helm repo update",
      "helm install --set provider='aws' --set distro='eks' --set splunkObservability.accessToken=$TOKEN --set clusterName=$EKS_CLUSTER_NAME --set splunkObservability.realm=$REALM --set otelCollector.enabled='false' --set splunkObservability.logsEnabled='true' --generate-name splunk-otel-collector-chart/splunk-otel-collector",

    ## Deploy Hot Rod
      "kubectl apply -f /home/ubuntu/deployment.yaml",
      # "sudo chmod +x /home/ubuntu/deploy_hotrod.sh",
      # "sudo chmod +x /home/ubuntu/delete_hotrod.sh",
      
    ## Write env vars to file (used for debugging)
      "echo $AWS_ACCESS_KEY_ID > /tmp/aws_access_key_id",
      "echo $AWS_SECRET_ACCESS_KEY > /tmp/aws_secret_access_key",
      "echo $REGION > /tmp/region",
      "echo $EKS_CLUSTER_NAME > /tmp/eks_cluster_name",
      "echo $TOKEN > /tmp/access_token",
      "echo $REALM > /tmp/realm",
      "echo $ENVIRONMENT > /tmp/environment",

    ## Configure motd
      "sudo curl -s https://raw.githubusercontent.com/signalfx/observability-workshop/master/cloud-init/motd -o /etc/motd",
      "sudo chmod -x /etc/update-motd.d/*",

    ]
  }

  # provisioner "remote-exec" {
  #   when = destroy
  #   on_failure = continue
  #   inline = [
  #     "kubectl delete -f /home/ubuntu/deployment.yaml"
  #   ]
  # }

  connection {
    host = self.public_ip
    type = "ssh"
    user = "ubuntu"
    private_key = file(var.private_key_path)
    agent = "true"
  }
}

output "eks_admin_server_details" {
  value =  formatlist(
    "%s, %s", 
    aws_instance.eks_admin_server.*.tags.Name,
    aws_instance.eks_admin_server.*.public_ip,
  )
}

# resource "null_resource" "hotrod" {
#   triggers = {
#     instance_ip_addr = aws_instance.eks_admin_server.public_ip,
#     private_key_path = var.private_key_path
#   }
#   depends_on = [
#     aws_eks_cluster.demo,
#     aws_instance.eks_admin_server
#   ]

#   provisioner "remote-exec" {
#     inline = [
#       # "/home/ubuntu/deploy_hotrod.sh"
#        "kubectl apply -f /home/ubuntu/deployment.yaml"
#     ]
#   }

#   provisioner "remote-exec" {
#     when = destroy
#     inline = [
#       # "/home/ubuntu/delete_hotrod.sh"
#        "kubectl delete -f /home/ubuntu/deployment.yaml"
#     ]
#   }

#   connection {
#     host = self.triggers.instance_ip_addr
#     type = "ssh"
#     user = "ubuntu"
#     private_key = file(self.triggers.private_key_path)
#     agent = "true"
#   }
# }