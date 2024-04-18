## Enable/Disable Modules - Values are set in quantity.auto.tfvars ###
variable "eks_cluster_enabled" {
  default = []
}
variable "eks_fargate_cluster_enabled" {
  default = []
}
variable "ecs_cluster_enabled" {
  default = []
}
variable "instances_enabled" {
  default = []
}
variable "proxied_instances_enabled" {
  default = []
}
variable "phone_shop_enabled" {
  default = []
}
variable "lambda_sqs_dynamodb_enabled" {
  default = []
}
variable "dashboards_enabled" {
  default = []
}
variable "detectors_enabled" {
  default = []
}
variable "itsi_o11y_cp_enabled" {
  default = []
}


### AWS Variables ###
variable "profile" {
  default = []
}
variable "aws_access_key_id" {
  default = []
}
variable "aws_secret_access_key" {
  default = []
}
variable "vpc_id" {
  default = []
}
variable "vpc_name" {
  default = []
}
variable "vpc_cidr_block" {
  default = []
}
variable "public_subnet_ids" {
  default = {}
}
variable "private_subnet_ids" {
  default = {}
}
variable "subnet_count" {
  default = {}
}
variable "key_name" {
  default = []
}
variable "private_key_path" {
  default = []
}
variable "instance_type" {
  default = []
}
variable "gateway_instance_type" {
  default = []
}
variable "mysql_instance_type" {
  default = []
}
variable "ms_sql_instance_type" {
  default = []
}
variable "ms_sql_agent_url" {
  description = "Path to the agent file to be used for MS SQL Servers"
  default     = {}
}
variable "windows_server_instance_type" {
  default = []
}
variable "windows_server_agent_url" {
  description = "Path to the agent file to be used for Windows Servers"
  default     = {}
}
variable "aws_api_gateway_deployment_retailorder_invoke_url" {
  default = {}
}
variable "my_public_ip" {
  default = []
}

## EKS Variables ##
variable "eks_cluster_name" {
  default = {}
}

## EKS-Fargate Variables ##
variable "eks_fargate_cluster_name" {
  default = {}
}

## AWS_ECS Variables ##
variable "ecs_agent_url" {
  description = "Path to the agent file to be used for ecs"
  default     = {}
}
variable "ecs_app_port" {
  description = "Port exposed by the docker image to redirect traffic to"
  default     = 8080
}
variable "ecs_az_count" {
  description = "Number of AZs to cover in a given region"
  default     = "3"
}
variable "ecs_health_check_path" {
  description = "Path used by ALB for Health Checks"
  default     = "/"
}
variable "ecs_app_image" {
  description = "Docker image to run in the ECS cluster"
  default     = "jaegertracing/example-hotrod"
}
variable "ecs_container_name" {
  description = "Name of the coantiner deployed in ECS"
  default     = "hotrod"
}
variable "ecs_fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "1024"
}
variable "ecs_fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default     = "2048"
}
variable "ecs_app_count" {
  description = "Number of docker containers to run"
  default     = 3
}

## Ubuntu AMI ##
data "aws_ami" "latest-ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # This is the owner id of Canonical who owns the official aws ubuntu images

  filter {
    name = "name"
    # values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# aws ec2 describe-images --owners
# owner id 801119661308

## MS SQL Server AMI ##
data "aws_ami" "ms-sql-server" {
  most_recent = true
  owners      = ["801119661308"]

  filter {
    name   = "name"
    # values = ["Windows_Server-2019-English-Full-SQL_2019_Standard-*"]
    values = ["Windows_Server-2022-English-Full-SQL_2022_Standard-*"]
    
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

## Windows Server AMI ##
data "aws_ami" "windows-server" {
  most_recent = true
  owners      = ["801119661308"]

  filter {
    name   = "name"
    # values = ["Windows_Server-2019-English-Full-ContainersLatest-*"]
    values = ["Windows_Server-2022-English-Full-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}




### Instance Count Variables ###
variable "gateway_count" {
  default = {}
}
variable "gateway_ids" {
  default = []
}
variable "haproxy_count" {
  default = {}
}
variable "haproxy_ids" {
  default = []
}
variable "mysql_count" {
  default = {}
}
variable "mysql_ids" {
  default = []
}
variable "mysql_user" {
  default = []
}
variable "mysql_user_pwd" {
  default = []
}
variable "ms_sql_count" {
  default = {}
}
variable "ms_sql_ids" {
  default = []
}
variable "ms_sql_user" {
  default = []
}
variable "ms_sql_user_pwd" {
  default = []
}
variable "ms_sql_administrator_pwd" {
  default = []
}
variable "windows_server_count" {
  default = {}
}
variable "windows_server_ids" {
  default = []
}
variable "windows_server_administrator_pwd" {
  default = []
}
variable "apache_web_count" {
  default = {}
}
variable "apache_web_ids" {
  default = []
}
variable "splunk_ent_count" {
  default = {}
}
variable "splunk_ent_ids" {
  default = []
}
variable "proxied_apache_web_count" {
  default = {}
}
variable "proxied_apache_web_ids" {
  default = []
}
variable "proxied_windows_server_count" {
  default = {}
}
variable "proxied_windows_server_ids" {
  default = []
}
variable "proxy_server_count" {
  default = {}
}
variable "proxy_server_ids" {
  default = []
}
variable "splunk_itsi_count" {
  default = {}
}
variable "splunk_itsi_ids" {
  default = []
}
# variable "xxx _count" {
#   default = {}
# }
# variable "xxx _ids" {
#   type = list(string)
#   default = []
# }

variable "region" {
  description = "Select region (1:eu-west-1, 2:eu-west-3, 3:eu-central-1, 4:us-east-1, 5:us-east-2, 6:us-west-1, 7:us-west-2, 8:ap-southeast-1, 9:ap-southeast-2, 10:sa-east-1 )"
}

variable "aws_region" {
  description = "Provide the desired region"
  default = {
    "1"  = "eu-west-1"
    "2"  = "eu-west-3"
    "3"  = "eu-central-1"
    "4"  = "us-east-1"
    "5"  = "us-east-2"
    "6"  = "us-west-1"
    "7"  = "us-west-2"
    "8"  = "ap-southeast-1"
    "9"  = "ap-southeast-2"
    "10" = "sa-east-1"
  }
}

## List available at https://github.com/signalfx/lambda-layer-versions/blob/master/python/PYTHON.md ##
variable "region_wrapper_python" {
  default = {
    "1"  = "arn:aws:lambda:eu-west-1:254067382080:layer:signalfx-lambda-python-wrapper:16"
    "2"  = "arn:aws:lambda:eu-west-3:254067382080:layer:signalfx-lambda-python-wrapper:16"
    "3"  = "arn:aws:lambda:ca-central-1:254067382080:layer:signalfx-lambda-python-wrapper:16"
    "4"  = "arn:aws:lambda:us-east-1:254067382080:layer:signalfx-lambda-python-wrapper:17"
    "5"  = "arn:aws:lambda:us-east-2:254067382080:layer:signalfx-lambda-python-wrapper:18"
    "6"  = "arn:aws:lambda:us-west-1:254067382080:layer:signalfx-lambda-python-wrapper:16"
    "7"  = "arn:aws:lambda:us-west-2:254067382080:layer:signalfx-lambda-python-wrapper:16"
    "8"  = "arn:aws:lambda:ap-southeast-1:254067382080:layer:signalfx-lambda-python-wrapper:16"
    "9"  = "arn:aws:lambda:ap-southeast-2:254067382080:layer:signalfx-lambda-python-wrapper:16"
    "10" = "arn:aws:lambda:sa-east-1:254067382080:layer:signalfx-lambda-python-wrapper:16"
  }
}

## List available at https://github.com/signalfx/lambda-layer-versions/blob/master/node/NODE.md ##
variable "region_wrapper_nodejs" {
  default = {
    "1"  = "arn:aws:lambda:eu-west-1:254067382080:layer:signalfx-lambda-nodejs-wrapper:24"
    "2"  = "arn:aws:lambda:eu-west-3:254067382080:layer:signalfx-lambda-nodejs-wrapper:24"
    "3"  = "arn:aws:lambda:eu-central-1:254067382080:layer:signalfx-lambda-nodejs-wrapper:25"
    "4"  = "arn:aws:lambda:us-east-1:254067382080:layer:signalfx-lambda-nodejs-wrapper:25"
    "5"  = "arn:aws:lambda:us-east-2:254067382080:layer:signalfx-lambda-nodejs-wrapper:25"
    "6"  = "arn:aws:lambda:us-west-1:254067382080:layer:signalfx-lambda-nodejs-wrapper:25"
    "7"  = "arn:aws:lambda:us-west-2:254067382080:layer:signalfx-lambda-nodejs-wrapper:25"
    "8"  = "arn:aws:lambda:ap-southeast-1:254067382080:layer:signalfx-lambda-nodejs-wrapper:24"
    "9"  = "arn:aws:lambda:ap-southeast-2:254067382080:layer:signalfx-lambda-nodejs-wrapper:24"
    "10" = "arn:aws:lambda:sa-east-1:254067382080:layer:signalfx-lambda-nodejs-wrapper:24"
  }
}


### SOC Variables ###
variable "soc_integration_id" {
  default = {}
}
variable "soc_routing_key" {
  default = {}
}

### SignalFX Variables ###
variable "access_token" {
  default = []
}
variable "api_url" {
  default = []
}
variable "realm" {
  default = []
}
variable "notification_email" {
  default = []
}
variable "smart_agent_version" {
  default = []
}
variable "environment" {
  default = {}
}
variable "otelcol_version" {
  default = {}
}
variable "windows_msi_url" {
  default = {}
}
variable "windows_fluentd_url" {
  default = {}
}
variable "windows_tdagent_conf_url" {
  default = {}
}
variable "windows_eventlog_conf_url" {
  default = {}
}
variable "windows_proxied_server_agent_url" {
  default = {}
}
variable "collector_version" {
  default = {}
}
variable "detector_promoting_tags_id" {
  default = {}
}
### Splunk Enterprise Variables ###
variable "splunk_ent_filename" {
  default = {}
}
variable "splunk_ent_version" {
  default = {}
}
variable "splunk_ent_inst_type" {
  default = {}
}
variable "universalforwarder_filename" {
  default = {}
}
variable "universalforwarder_url" {
  default = {}
}
variable "splunk_enterprise_files_local_path" {
  default = {}
}
variable "splunk_enterprise_license_filename" {
  default = {}
}
# variable "splunk_password" {
#   default = {}
# }

### Splunk ITSI Variables ###
variable "splunk_itsi_filename" {
  default = {}
}
variable "splunk_itsi_version" {
  default = {}
}
variable "splunk_itsi_inst_type" {
  default = {}
}
variable "splunk_itsi_files_local_path" {
  default = {}
}
variable "splunk_itsi_license_filename" {
  default = {}
}
variable "splunk_app_for_content_packs_filename" {
  default = {}
}
variable "splunk_it_service_intelligence_filename" {
  default = {}
}
variable "splunk_synthetic_monitoring_add_on_filename" {
  default = {}
}
variable "splunk_infrastructure_monitoring_add_on_filename" {
  default = {}
}