data "aws_security_group" "vpc_default_sg" {
  name   = "default"
  vpc_id = aws_vpc.main_vpc.id
}

resource "null_resource" "delete_vpc_default_security_group_ingress_rule" {
  triggers = {
    default_security_group_id = data.aws_security_group.vpc_default_sg.id
  }

  provisioner "local-exec" {
    command = "AWS_ACCESS_KEY_ID=${var.aws_access_key_id} AWS_SECRET_ACCESS_KEY=${var.aws_secret_access_key} aws ec2 revoke-security-group-ingress --group-id ${data.aws_security_group.vpc_default_sg.id} --protocol all --port all --source-group ${data.aws_security_group.vpc_default_sg.id} --region ${var.region}"
  }
}

resource "null_resource" "delete_vpc_default_security_group_egress_rule" {
  triggers = {
    default_security_group_id = data.aws_security_group.vpc_default_sg.id
  }

  provisioner "local-exec" {
    command = "AWS_ACCESS_KEY_ID=${var.aws_access_key_id} AWS_SECRET_ACCESS_KEY=${var.aws_secret_access_key} aws ec2 revoke-security-group-egress --group-id ${data.aws_security_group.vpc_default_sg.id} --protocol all --port all --cidr 0.0.0.0/0 --region ${var.region}"
  }
}