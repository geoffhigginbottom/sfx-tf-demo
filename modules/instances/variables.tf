### AWS Variables ###
variable "region" {
  default = {}
}
variable "vpc_id" {
  default = []
}
variable "vpc_cidr_block" {
  default = []
}
variable "public_subnet_ids" {
  default = {}
}
variable "key_name" {
  default = []
}
variable "private_key_path"{
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
variable "windows_server_instance_type" {
  default = []
}
variable "ami" {
  default = {}
}
variable "ms_sql_ami" {
  default = {}
}
variable "windows_server_ami" {
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
variable "smart_agent_version" {
  default = []
}
variable "otelcol_version" {
  default = []
}
variable "ballast" {
  default = []
}
variable "environment" {
  default = []
}
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
variable "ms_sql_agent_url" {
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
variable "windows_server_agent_url" {
  default = []
}
variable "windows_server_administrator_pwd" {
  default =[]
}
variable "apache_web_count" {
  default = {}
}
variable "apache_web_ids" {
  default = []
}
variable "branch" {
  default = []
}


### Splunk Enterprise Variables ###
variable "splunk_ent_count" {
  default = {}
}
variable "splunk_ent_ids" {
  default = []
}
variable "splunk_ent_version" {
  default = {}
}
variable "splunk_ent_filename" {
  default = {}
}
variable "splunk_ent_inst_type" {
  default = {}
}