resource "aws_security_group" "demo-cluster" {
  # name                = "terraform-eks-demo-cluster"
  name                = "${var.environment}_eks_cluster_sg"
  description         = "Cluster communication with worker nodes"
  vpc_id              = var.vpc_id

  egress {
    from_port         = 0
    to_port           =  0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
  }

  ingress {
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
    cidr_blocks       = [var.vpc_cidr_block]
  }

  # tags = {
  #   Name              = "terraform-eks-demo"
  # }
}

resource "aws_security_group" "eks_admin_server" {
  # name                = "eks_admin_server"
  name                = "${var.environment}_eks_admin_server_sg"
  description         = "Remote access to EKS Admin Server"
  vpc_id              = var.vpc_id

  ingress {
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
  }

  egress {
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
  }

  # tags = {
    # Name              = "terraform-eks-demo"
  # }
}


