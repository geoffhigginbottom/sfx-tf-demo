output "gateway_lb_int_dns" {
  value = aws_lb.gateway-lb.dns_name
  description = "The Internal DNS address assigned to the Gateway Internal Load Balancer"
}
