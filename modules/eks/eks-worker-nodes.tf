resource "aws_eks_node_group" "demo" {
  cluster_name    = aws_eks_cluster.demo.name
  # node_group_name = "demo"
  node_group_name = join("_",[var.environment,"eks_node_group"])
  node_role_arn   = aws_iam_role.demo-node.arn
  subnet_ids      = var.public_subnet_ids
  instance_types  = ["t2.xlarge"]
  disk_size       = 100 # testing this new setting - default is 20

  scaling_config {
    desired_size = 4
    max_size     = 6
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.demo-node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.demo-node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.demo-node-AmazonEC2ContainerRegistryReadOnly,
  ]
}
