resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.splunk_ent[0].id
  public_ip     = "54.78.7.27"
  count         = var.splunk_ent_count
}


output "splunk_ent_details" {
  value =  formatlist(
    "%s, %s", 
    aws_instance.splunk_ent.*.tags.Name,
    # aws_instance.splunk_ent.*.public_ip,
    aws_eip_association.eip_assoc.*.public_ip
  )
}

output "splunk_ent_urls" {
  value =  formatlist(
    "%s%s:%s", 
    "http://",
    # aws_instance.splunk_ent.*.public_ip,
    aws_eip_association.eip_assoc.*.public_ip,
    "8000",
  )
}