resource "aws_lb_target_group" "gateway-lb-tg-4318" {
  name     = "gateway-lb-tg-4318"
  port     = 4318
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  
  health_check {
    path = "/"
    port = 13133
    healthy_threshold = 5
    unhealthy_threshold = 2
    timeout = 2
    interval = 5
    matcher = "200"  # has to be HTTP 200 or fails
  }
}

resource "aws_lb_target_group_attachment" "gateway-lb-tg-4318-attachment" {
  count            = var.gateway_count
  target_group_arn = aws_lb_target_group.gateway-lb-tg-4318.arn
  target_id        = aws_instance.gateway[count.index].id
  port             = 4318
}

resource "aws_lb_target_group" "gateway-lb-tg-9943" {
  name     = "gateway-lb-tg-9943"
  port     = 9943
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  
#   lifecycle { create_before_destroy=true }

  health_check {
    path = "/"
    port = 13133
    healthy_threshold = 5
    unhealthy_threshold = 2
    timeout = 2
    interval = 5
    matcher = "200"  # has to be HTTP 200 or fails
  }
}

resource "aws_lb_target_group_attachment" "gateway-lb-tg-9943-attachment" {
  count            = var.gateway_count
  target_group_arn = aws_lb_target_group.gateway-lb-tg-9943.arn
  target_id        = aws_instance.gateway[count.index].id
  port             = 9943
}

resource "aws_lb_target_group" "gateway-lb-tg-6060" {
  name     = "gateway-lb-tg-6060"
  port     = 6060
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  
#   lifecycle { create_before_destroy=true }

  health_check {
    path = "/"
    port = 13133
    healthy_threshold = 5
    unhealthy_threshold = 2
    timeout = 2
    interval = 5
    matcher = "200"  # has to be HTTP 200 or fails
  }
}

resource "aws_lb_target_group_attachment" "gateway-lb-tg-6060-attachment" {
  count            = var.gateway_count
  target_group_arn = aws_lb_target_group.gateway-lb-tg-6060.arn
  target_id        = aws_instance.gateway[count.index].id
  port             = 6060
}

resource "aws_lb_target_group" "gateway-lb-tg-9411" {
  name     = "gateway-lb-tg-9411"
  port     = 9411
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  
#   lifecycle { create_before_destroy=true }

  health_check {
    path = "/"
    port = 13133
    healthy_threshold = 5
    unhealthy_threshold = 2
    timeout = 2
    interval = 5
    matcher = "200"  # has to be HTTP 200 or fails
  }
}

resource "aws_lb_target_group_attachment" "gateway-lb-tg-9411-attachment" {
  count            = var.gateway_count
  target_group_arn = aws_lb_target_group.gateway-lb-tg-9411.arn
  target_id        = aws_instance.gateway[count.index].id
  port             = 9411
}



# resource "aws_lb_target_group" "gateway-lb-tg-7276" {
#   name     = "gateway-lb-tg-7276"
#   port     = 7276
#   protocol = "HTTP"
#   vpc_id   = var.vpc_id
  
# #   lifecycle { create_before_destroy=true }

#   health_check {
#     path = "/"
#     port = 13133
#     healthy_threshold = 5
#     unhealthy_threshold = 2
#     timeout = 2
#     interval = 5
#     matcher = "200"  # has to be HTTP 200 or fails
#   }
# }

# resource "aws_lb_target_group_attachment" "gateway-lb-tg-7276-attachment" {
#   count            = var.gateway_count
#   target_group_arn = aws_lb_target_group.gateway-lb-tg-7276.arn
#   target_id        = aws_instance.gateway[count.index].id
#   port             = 7276
# }

# resource "aws_lb_target_group" "gateway-lb-tg-55681" {
#   name     = "gateway-lb-tg-55681"
#   port     = 55681
#   protocol = "HTTP"
#   vpc_id   = var.vpc_id
  
# #   lifecycle { create_before_destroy=true }

#   health_check {
#     path = "/"
#     port = 13133
#     healthy_threshold = 5
#     unhealthy_threshold = 2
#     timeout = 2
#     interval = 5
#     matcher = "200"  # has to be HTTP 200 or fails
#   }
# }

# resource "aws_lb_target_group_attachment" "gateway-lb-tg-55681-attachment" {
#   count            = var.gateway_count
#   target_group_arn = aws_lb_target_group.gateway-lb-tg-55681.arn
#   target_id        = aws_instance.gateway[count.index].id
#   port             = 55681
# }
