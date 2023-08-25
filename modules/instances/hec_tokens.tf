
# resource "splunk_inputs_http_event_collector" "hec-token-01" {
#   name       = "hec-token-01"
#   index      = "k8s-logs"
#   indexes    = ["k8s-logs", "main"]
# #   source     = "new:source"
# #   sourcetype = "automatic"
#   disabled   = false
# #   use_ack    = 0
# }