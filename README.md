# Splunk Observability Terraform Demo

# Introduction

This is a collection of Terraform Modules which can be used to deploy a test environment into a new AWS VPC.  The purpose is to enable you to deploy some typical AWS resources, and at the same time, deploy Splunk Infrastructure Monitoring and Splunk Application Performance Monitoring, combining "Infrastructure as Code" with "Monitoring as Code". The aim is to provide fully configured working examples to supplement the official Splunk documentation.

# Requirements

To use this repo, you need an active AWS account. Where possible resources that qualify for the free tier are used by default to enable deployment to AWS trial accounts with minimal costs.

You will also need a Splunk Infrastructure Monitoring Account. Some modules leverage the Splunk APM features so ideally you will also have APM enabled on your Splunk environment.

The "Detectors" Module requires a Splunk On-Call account with an active integration to Splunk IM, enabling end to end testing of both "Monitoring" and "Incident Response".

# Setup

After cloning the repo, you need to generate and configure a terraform.tfvars file that will be unique to you and will not be synced back to the repo (if you are contributing to this repo).

Copy the included terraform.tfvars.example file to terraform.tfvars

```bash
cp terraform.tfvars.example terraform.tfvars
```

Update the contents of terraform.tfvars replacing any value contained within <> to suit your environment.  Note some values have been pre-populated with typical values, ensure you review every setting and update as appropriate.

Any value can be removed or commented out with a #, by doing so Terraform will prompt you for the appropriate value at run time.

The following describes each section of terraform.tfvars:

## terraform.tfvars

### Enable / Disable Modules

There are a number of core modules which are always deployed such as VPC and Security Groups, but the modules listed under the 'Enable / Disable Modules' comment can be activated by changing the values from the default of "false" to "true".

You will find more information about each Module at the end of this document.

There are generally no interdependencies between modules, so you can deploy almost any combination, but if enabling Dashboards, you should also enable Detectors.  The 'EKS Cluster', 'ECS Cluster' and 'Phone Shop' modules all have APM enabled and are instrumented to emit Traces.

The quantities of each EC2 Instance deployed as part of the 'Instances & Proxied Instances' Modules are also controlled here. You can deploy between 0 & 3 of most types, but you should always deploy at least 1 Gateway (Instances Module), which gets deployed behind an AWS ALB, and is used by the Instances to send in their metrics to the Splunk IM Platform.

```yaml
# This file contains all the settings which are unique to each deployment and it
# should NOT be stored in a public source control system as it contains sensitive information
# If values are commented out, you will be prompted for them at run time, this way you 
# can choose to store the information in this file, or enter it at run time.

### Enable / Disable Modules
eks_cluster_enabled         = false
ecs_cluster_enabled         = false
instances_enabled           = false
proxied_instances_enabled   = false
itsi_o11y_cp_enabled        = false
phone_shop_enabled          = false
lambda_sqs_dynamodb_enabled = false
dashboards_enabled          = false
detectors_enabled           = false

## Instance Quantities ##
gateway_count = "2" # min 1 : max = subnet_count - there should always be at least one as Target Groups require one
gateway_ids = [
  "gateway1",
  "gateway2",
  "gateway3"
  ]

haproxy_count = "1" # min 0 : max = subnet_count
haproxy_ids = [
  "haproxy1",
  "haproxy2",
  "haproxy3"
  ]

mysql_count = "1" # min 0 : max = subnet_count
mysql_ids = [
  "mysql1",
  "mysql2",
  "mysql3"
  ]

ms_sql_count = "1" # min 0 : max = subnet_count
ms_sql_ids = [
  "ms_sql1",
  "ms_sql2",
  "ms_sql3"
  ]

windows_server_count = "1" # min 0 : max = subnet_count
windows_server_ids = [
  "windows1",
  "windows2",
  "windows3"
  ]

apache_web_count = "1" # min 0 : max = subnet_count
apache_web_ids = [
  "apache1",
  "apache2",
  "apache3"
  ]

splunk_ent_count = "1" # min 0 : max = 1 as only one is required, used as a yes/no parameter
splunk_ent_ids = [
  "splunk-ent"
  ]

## Proxied Instances Quantities ##

proxy_server_count = "1" # min 0 : max = 1 as only one is required, used as a yes/no parameter
proxy_server_ids = [
  "proxy-server"
  ]

proxied_apache_web_count = "1" # min 0 : max = subnet_count
proxied_apache_web_ids = [
  "proxied-apache_1",
  "proxied-apache_2",
  "proxied-apache_3"
  ]

proxied_windows_server_count = "1" # min 0 : max = subnet_count
proxied_windows_server_ids = [
  "proxied-windows1",
  "proxied-windows2",
  "proxied-windows3"
  ]

## ITSI Quantities ##

splunk_itsi_count = "1" # min 0 : max = 1 as only one is required, used as a yes/no parameter
splunk_itsi_ids = [
  "splunk-itsi"
  ]
```

### AWS Variables

This section details the parameters required by AWS such as Region (see below for more info on this), VPC settings, SSH Auth Key, and authentication to your AWS account.

#### Region

When you run the deployment terraform will prompt you for a Region, however if you enable the setting here, and populate it with a numerical value representing your preferred AWS Region, it will save you having to enter a value on each run. The settings for this are controlled via variables.tf, but the valid options are:

- 1: eu-west-1
- 2: eu-west-3
- 3: eu-central-1
- 4: us-east-1
- 5: us-east-2
- 6: us-west-1
- 7: us-west-2
- 8: ap-southeast-1
- 9: ap-southeast-2
- 10: sa-east-1

#### VPC Settings

A new VPC is created and is used by all the modules with the exception of the the ECS Cluster Module creates its own VPC.  The number of subnets is controlled by the 'subnet_count' parameter, and defaults to 2 which should be sufficient for most test cases.

Two sets of subnets will be created, a Private and a Public Subnet, so by default 4 subnets will be created. Each Subnet will be created using a CIDR allocated from the 'vpc_cidr_block', so by default the 1st subnet will use 172.32.0.0/24, the 2nd subnet will use 172.32.1.0/24 etc.

Note: The ECS Cluster Module will create its own unique VPC and Subnets and creates a Fargate deployment.  At present all the variables controlling this are contained within the ECS Cluster modules variables.tf file (modules/aws_ecs/variables.tf).

```yaml
### AWS Variables ###
#region = "<REGION>"

## VPC Settings ##
vpc_cidr_block        = "172.32.0.0/16"
subnet_count          = "2" 

## Auth Settings ##
key_name              = "<NAME>"
private_key_path      = "~/.ssh/id_rsa"
instance_type         = "t2.micro"
aws_access_key_id     = "<ACCCESS_KEY_ID>>"
aws_secret_access_key = "<SECRET_ACCESS_KEY>>"
```

### SOC Variables

Settings used by the Splunk On-Call Integration within Splunk IM/APM to create Incidents from the Alerts generated by Splunk IM/APM.

```yaml
### SOC Variables ###
soc_integration_id  = "<ID>"
soc_routing_key     = "<ROUTING_KEY>"
```

### Splunk IM/APM Variables

Settings used by Splunk IM/APM for authentication, notifications and APM Environment.  An example of an Environment value would be "TF Demo", it's a simple tag used to identify and link the various components within the Splunk APM UI.

Optionally you can specify a version for the smart_agent, but if left blank the latest will be used, which is the recommended option, however as OTEL is replacing the SmartAgent this setting will soon be retired.

The collector_version is currently only used by the Proxied Instances module as it leverages an offline installation method which requires the version number to be specified, all other modules that use OTEL will use the latest by default.

```yaml
### Splunk IM/APM Variables ###
access_token             = "<ACCESS_TOKEN>"
api_url                  = "https://api.<REALM>.signalfx.com"
realm                    = "<REALM>"
environment              = "<ENVIRONMENT>"
notification_email       = "<EMAIL>"
smart_agent_version      = "" # Optional - If left blank, latest will be installed - example value would be "5.7.1-1"
ecs_agent_url            = "https://raw.githubusercontent.com/geoffhigginbottom/sfx-tf-demo/master/modules/aws_ecs/agent_fargate.yaml"
ms_sql_agent_url         = "https://raw.githubusercontent.com/geoffhigginbottom/sfx-tf-demo/Master/modules/instances/config_files/ms_sql_agent_config.yaml"
windows_server_agent_url = "https://raw.githubusercontent.com/geoffhigginbottom/sfx-tf-demo/Master/modules/instances/config_files/windows_server_agent_config.yaml"
collector_version        = "0.40.0"
```

### Gateway Variables

One or more OpenTelemetry Gateways are deployed as part of the Instances Module, behind an ELB, and are configured for both IM and APM.

```yaml
### Gateway Variables ###
### https://quay.io/repository/signalfx/splunk-otel-collector?tab=tags
gateway_instance_type = "t2.small"
```

### Splunk Enterprise Variables

The instances module can also deploy a Splunk Enterprise VM but you need to provide the file name and version of the release you want to use as hosted on https://www.splunk.com/en_us/download/splunk-enterprise.html

```yaml
### Splunk Enterprise Variables ###
splunk_ent_filename     = "splunk-8.2.3-cd0848707637-linux-2.6-amd64"
splunk_ent_version      = "8.2.3"
splunk_ent_inst_type    = "t2.large"
```

### Splunk ITSI Variables

The Splunk ITSI Module requires various files that cannot be included in this repo and need to be downloaded from https://splunkbase.splunk.com/ then their locations specified in this section

```yaml
### Splunk ITSI Variables ###
splunk_itsi_inst_type                             = "t2.large"
splunk_itsi_version                               = "8.2.3"
splunk_itsi_filename                              = "splunk-8.2.3-cd0848707637-linux-2.6-amd64.deb"
splunk_itsi_files_local_path                      = "~/Downloads" # path where itsi files resides on your local machine 
splunk_itsi_license_filename                      = "Splunk_ITSI_NFR_FY23.lic" # this file should NOT be included in the repo, and shoule be located in the itsi_files_local_path location
splunk_app_for_content_packs_filename             = "splunk-app-for-content-packs_140.spl" # this file should NOT be included in the repo, and shoule be located in the itsi_files_local_path location
splunk_it_service_intelligence_filename           = "splunk-it-service-intelligence_493.spl" # this file should NOT be included in the repo, and shoule be located in the itsi_files_local_path location
splunk_synthetic_monitoring_add_on_filename       = "splunk-synthetic-monitoring-add-on_107.tgz" # this file should NOT be included in the repo, and shoule be located in the itsi_files_local_path location
splunk_infrastructure_monitoring_add_on_filename  = "splunk-infrastructure-monitoring-add-on_121.tgz" # this file should NOT be included in the repo, and shoule be located in the itsi_files_local_path location
```

## Windows SQL Servers Variables

The Microsoft SQL Server Instance requires Windows and SQL Admin Passwords to be set

```yaml
### MS SQL Server Variables ###
ms_sql_user                   = "signalfxagent"
ms_sql_user_pwd               = "<STRONG_PWD>"
ms_sql_administrator_pwd      = "<STRONG_PWD>"
ms_sql_instance_type          = "t3.xlarge"
```

## Windows Servers Variables

The Microsoft Windows Server Instance requires Windows Admin Password to be set

```yaml
### Windows Server Variables ###
windows_server_administrator_pwd  = "<STRONG_PWD>"
windows_server_instance_type      = "t3.xlarge"
```

## MySQL Server Variables

The MySQL Server Instance requires SQL User Password to be set

```yaml
### MySQL Server Variables ###
mysql_user             = "signalfxagent"
mysql_user_pwd         = "<STRONG_PWD>"
```

# Modules

Details about each module can be found below

## Instances

This module deploys some example EC2 Instances, with Splunk IM Monitors matching their role, as well as Otel Collectors. Each instance is deployed with an otel collector running in agent mode to enable Infrastructure Monitoring and is configured to send all metrics via the cluster of Otel Collectors, fronted by an AWS Load Balancer.

The following EC2 Instances can be deployed:

- Gateways
- HAProxy
- MySQL
- Microsoft SQL Server
- Microsoft Windows Server
- Apache
- Splunk Enterprise

Each Instance has Infrastructure Monitoring 'receivers' configured to match the services running on them.  The configuration for each monitor is deployed via its own specific agent_config.yaml file.

## Proxied Instances

This module deploys some sample instances which are deployed with no internet access, and are forced to use an inline-proxy for sending their metrics back to the splunk endpoints.  This introduces a number of challenges which are addressed in this module.

## Splunk ITSI

This module deploys a Splunk ITSI Instance, and sets up a number of content packs and add-ons, which are all automatically installed and configured.

## Phone Shop

This is based on the Lambda components of the [Splunk Observability Workshop](https://signalfx.github.io/observability-workshop/latest/), but unlike the workshop version, is fully configured for APM.  As well as deploying the Lambda Functions fully instrumented, and their required API Gateways, the EC2 Instance 'vm_phone_shop' is configured to automatically generate random load to ensure APM Traces are generated within a couple of minutes of deployment.

## Lambda SQS DynamoDB

This module deploys a Lambda function which is triggered by an SQS queue, storing the messages from the queue into a DynamoDB table.  An EC2 Instance 'vm_sqs_test_server' is deployed and this instance contains a helper script called 'generate_send_messages' which is deployed into the ubuntu users home folder.  When run, this script places random messages into SQS, triggering the Lambda function which then removes the messages placing them into the DynamoDB table.  This enables testing of SQS triggered Lambda functions when using APM.

## Dashboards

This module creates a new Dashboard Group with an example Dashboard generated by Terraform.  The aim of this module is to simply demonstrate the methods for creating new Dashboard Groups, Charts and Dashboards, using "Monitoring as Code", in parallel with your "Infrastructure as Code" via Terraform.

## Detectors

This module creates a couple of new Detectors as basic examples of creating detectors and leveraging the integration with Splunk On-Call.  A more comprehensive list of example detectors which can be deployed using Terraform can be found [here](https://github.com/signalfx/signalfx-jumpstart).
