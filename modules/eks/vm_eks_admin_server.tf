resource "aws_instance" "eks_admin_server" {
  ami                       = var.ami
  instance_type             = var.instance_type
  subnet_id                 = element(var.public_subnet_ids, 0)
  key_name                  = var.key_name
  vpc_security_group_ids    = [
    aws_security_group.eks_admin_server.id,
  ]
 
  tags = {
    Name = "${var.environment}_eks_admin_server"
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

  # provisioner "file" {
  #   source      = "${path.module}/config_files/deployment.yaml"
  #   destination = "/home/ubuntu/deployment.yaml"
  # }

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
      # "/tmp/generate_values.sh $ENVIRONMENT", #is this still needed as hotrod has been removed

    ## Setup eksutils
      "AWS_DEFAULT_REGION=${var.region}",
      "AWS_DEFAULT_OUTPUT=json",
      "EKS_CLUSTER_NAME=${var.eks_cluster_name}",
      "eksctl utils write-kubeconfig --cluster=$EKS_CLUSTER_NAME",
      "eksctl get clusters",
      "aws eks update-kubeconfig --name $EKS_CLUSTER_NAME",

    # ## Install K8S Integration using OTEL
    #   "TOKEN=${var.access_token}",
    #   "REALM=${var.realm}",
    #   "EKS_CLUSTER_NAME=${var.eks_cluster_name}",
    #   "helm repo add splunk-otel-collector-chart https://signalfx.github.io/splunk-otel-collector-chart",
    #   "helm repo update",
    #   "helm install --set cloudProvider='aws' --set distribution='eks' --set splunkObservability.accessToken=$TOKEN --set clusterName=$EKS_CLUSTER_NAME --set splunkObservability.realm=$REALM --set gateway.enabled='false' --set splunkObservability.profilingEnabled='true' --generate-name splunk-otel-collector-chart/splunk-otel-collector",
    #   # "helm install --set cloudProvider='aws' --set distribution='eks' --set splunkObservability.accessToken=$TOKEN --set clusterName=$EKS_CLUSTER_NAME --set splunkObservability.realm=$REALM --set gateway.enabled='false' --set splunkObservability.profilingEnabled='true' --set splunkPlatform.endpoint=$protocol://$ipaddress:8088/services/collector --set splunkPlatform.token=$hec_token --set splunkPlatform.index=k8s-logs, --generate-name splunk-otel-collector-chart/splunk-otel-collector",
    #   # "helm install --set cloudProvider='aws' --set distribution='eks' --set splunkObservability.accessToken=dAb_HPT5SSP243Af4lYikg --set clusterName=tfdemo_eks_cluster --set splunkObservability.realm=eu0 --set gateway.enabled='false' --set splunkObservability.profilingEnabled='false' --set splunkPlatform.endpoint=https://http-inputs-scv-shw-0b83708c1db0ac.stg.splunkcloud.com/services/collector/raw --set splunkPlatform.token=06686ce3-5794-4683-a69d-b005c16a948a --set splunkPlatform.index=geoff_test_2, --generate-name splunk-otel-collector-chart/splunk-otel-collector",
    #   # "helm install --set cloudProvider='aws' --set distribution='eks' --set splunkObservability.accessToken=dAb_HPT5SSP243Af4lYikg --set clusterName=tfdemo_eks_cluster --set splunkObservability.realm=eu0 --set gateway.enabled='false' --set splunkObservability.profilingEnabled='false' --set splunkPlatform.endpoint=http://eip1.geoffh.co.uk:8088 --set splunkPlatform.token=e93d2724-43eb-4e4d-ad23-40474059c1f5 --set splunkPlatform.index=k8s-logs, --generate-name splunk-otel-collector-chart/splunk-otel-collector",
      

    ## Deploy Hot Rod
      # "kubectl apply -f /home/ubuntu/deployment.yaml",
      # "sudo chmod +x /home/ubuntu/deploy_hotrod.sh",
      # "sudo chmod +x /home/ubuntu/delete_hotrod.sh",
      
    ## Deploy Astro Shop
      "git clone https://github.com/splunk/observability-workshop",
      "helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts",
      "helm install astro-shop-demo open-telemetry/opentelemetry-demo --values ~/observability-workshop/workshop/oteldemo/otel-demo.yaml",

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
  #     "sudo helm delete"
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

# ## Deploy the Astro Shop 
# # Usees the Null Resource as it needs to be deleted during destroy phase as the VPC 
# # will not delete if the Load Balancer created by the deploment is still present.
# # Triggers are used because "Destroy-time provisioners and their connection configurations may 
# # only reference attributes of the related resource, via 'self', 'count.index', or 'each.key'"

# resource "null_resource" "astroshop" {
#   count      = 1
  
#   triggers = {
#     instance_ip_addr = aws_instance.eks_admin_server.public_ip,
#     private_key_path = var.private_key_path
#   }

#   depends_on = [
#     aws_eks_cluster.demo,
#     aws_instance.eks_admin_server
#   ]

#   connection {
#     type = "ssh"
#     user = "ubuntu"
#     # private_key = file(var.private_key_path)
#     private_key = file(self.triggers.private_key_path)
#     # host = aws_instance.eks_admin_server.public_ip
#     host = self.triggers.instance_ip_addr
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "git clone https://github.com/splunk/observability-workshop",
#       "helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts",
#       "helm install astro-shop-demo open-telemetry/opentelemetry-demo --values ~/observability-workshop/workshop/oteldemo/otel-demo.yaml",
#     ]
#   }

#   provisioner "remote-exec" {
#     when = destroy
#     inline = [
#       "helm delete my-otel-demo"
#     ]
#   }
# }