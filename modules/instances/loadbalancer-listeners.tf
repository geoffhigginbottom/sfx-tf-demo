resource "aws_lb_listener" "gateway-lb-listener-4318" {
  default_action {
    target_group_arn = aws_lb_target_group.gateway-lb-tg-4318.arn
    type = "forward"
  }
  load_balancer_arn = aws_lb.gateway-lb.arn
  port = 4318
  protocol = "HTTP"
}

resource "aws_lb_listener_rule" "rule-4318" {
  listener_arn = aws_lb_listener.gateway-lb-listener-4318.id
  priority = 100

  action {
    target_group_arn = aws_lb_target_group.gateway-lb-tg-4318.arn
    type = "forward"
  }

  condition {
    path_pattern {
      values = ["/static/*"]
    }
  }
}


resource "aws_lb_listener" "gateway-lb-listener-9943" {
  default_action {
    target_group_arn = aws_lb_target_group.gateway-lb-tg-9943.arn
    type = "forward"
  }
  load_balancer_arn = aws_lb.gateway-lb.arn
  port = 9943
  protocol = "HTTP"
}

resource "aws_lb_listener_rule" "rule-9943" {
  listener_arn = aws_lb_listener.gateway-lb-listener-9943.id
  priority = 100

  action {
    target_group_arn = aws_lb_target_group.gateway-lb-tg-9943.arn
    type = "forward"
  }

  condition {
    path_pattern {
      values = ["/static/*"]
    }
  }
}

resource "aws_lb_listener" "gateway-lb-listener-6060" {
  default_action {
    target_group_arn = aws_lb_target_group.gateway-lb-tg-6060.arn
    type = "forward"
  }
  load_balancer_arn = aws_lb.gateway-lb.arn
  port = 6060
  protocol = "HTTP"
}

resource "aws_lb_listener_rule" "rule-6060" {
  listener_arn = aws_lb_listener.gateway-lb-listener-6060.id
  priority = 100

  action {
    target_group_arn = aws_lb_target_group.gateway-lb-tg-6060.arn
    type = "forward"
  }

  condition {
    path_pattern {
      values = ["/static/*"]
    }
  }
}

resource "aws_lb_listener" "gateway-lb-listener-9411" {
  default_action {
    target_group_arn = aws_lb_target_group.gateway-lb-tg-9411.arn
    type = "forward"
  }
  load_balancer_arn = aws_lb.gateway-lb.arn
  port = 9411
  protocol = "HTTP"
}

resource "aws_lb_listener_rule" "rule-9411" {
  listener_arn = aws_lb_listener.gateway-lb-listener-9411.id
  priority = 100

  action {
    target_group_arn = aws_lb_target_group.gateway-lb-tg-9411.arn
    type = "forward"
  }

  condition {
    path_pattern {
      values = ["/static/*"]
    }
  }
}




# resource "aws_lb_listener" "gateway-lb-listener-7276" {
#   default_action {
#     target_group_arn = aws_lb_target_group.gateway-lb-tg-7276.arn
#     type = "forward"
#   }
#   load_balancer_arn = aws_lb.gateway-lb.arn
#   port = 7276
#   protocol = "HTTP"
# }

# resource "aws_lb_listener_rule" "rule-7276" {
#   listener_arn = aws_lb_listener.gateway-lb-listener-7276.id
#   priority = 100

#   action {
#     target_group_arn = aws_lb_target_group.gateway-lb-tg-7276.arn
#     type = "forward"
#   }

#   condition {
#     path_pattern {
#       values = ["/static/*"]
#     }
#   }
# }

# resource "aws_lb_listener" "gateway-lb-listener-55681" {
#   default_action {
#     target_group_arn = aws_lb_target_group.gateway-lb-tg-55681.arn
#     type = "forward"
#   }
#   load_balancer_arn = aws_lb.gateway-lb.arn
#   port = 55681
#   protocol = "HTTP"
# }

# resource "aws_lb_listener_rule" "rule-55681" {
#   listener_arn = aws_lb_listener.gateway-lb-listener-55681.id
#   priority = 100

#   action {
#     target_group_arn = aws_lb_target_group.gateway-lb-tg-55681.arn
#     type = "forward"
#   }

#   condition {
#     path_pattern {
#       values = ["/static/*"]
#     }
#   }
# }
