resource "signalfx_detector" "promote_tags" {
  name         = "${var.environment} Promoting Tags"
  description  = "Promoting Tags"
  max_delay    = 1
  program_text = <<-EOF
    A = data('cpu.utilization').promote('aws_tag_Name', 'aws_tag_Environment', allow_missing=True).publish(label='A')
    detect(when(A > threshold(80))).publish('Promoting Tags')
  EOF
  rule {
    description           = "Promoting Tags"
    severity              = "Critical"
    detect_label          = "Promoting Tags"
    notifications         = ["Email,${var.notification_email}"]
    parameterized_subject = "{{ruleSeverity}} Alert: {{{ruleName}}} ({{{detectorName}}})"
    parameterized_body    = var.message_body_promote
    disabled              = true
  }
}

output "detector_promoting_tags_id" {
  value = signalfx_detector.promote_tags.id
  description = "ID of the Promoting Tags Detector"
}
