resource "random_string" "splunk_password" {
  length           = 12
  special          = false
  # override_special = "@£$"
}

output "splunk_password" {
  value = random_string.splunk_password.result
  # value = var.splunk_password
}