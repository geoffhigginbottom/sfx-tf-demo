resource "signalfx_detector" "promote_tags_cw" {
  name         = "${var.environment} Promoting Tags CW"
  description  = "Promoting Tags CW"
  max_delay    = 1
  program_text = <<-EOF
    A = data('^aws.ec2.cpu.utilization').promote('aws_tag_Name', 'aws_tag_Environment', allow_missing=True).publish(label='A')
    detect(when(A > threshold(80))).publish('Promoting Tags CW')
  EOF
  rule {
    description           = "Promoting Tags CW"
    severity              = "Critical"
    detect_label          = "Promoting Tags CW"
    notifications         = ["Email,${var.notification_email}"]
    parameterized_subject = "{{ruleSeverity}} Alert: {{{ruleName}}} ({{{detectorName}}})"
    parameterized_body    = var.message_body_promote
    disabled              = true
  }
}