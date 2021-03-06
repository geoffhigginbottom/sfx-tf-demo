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
variable "collector_instance_type" {
  default = []
}
variable "ami" {
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

variable "collector_count" {
  default = {}
}
variable "collector_ids" {
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
variable "wordpress_count" {
  default = {}
}
variable "wordpress_ids" {
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