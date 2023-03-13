# Create Memory Used Chart Graph
resource "signalfx_time_chart" "mem_used_chart_graph" {
  name = "Memory Used %"

    program_text = <<-EOF
        A = data('memory.utilization').publish(label='A')
        EOF
        
    plot_type = "LineChart"
    show_data_markers = true

    description = "percentile distribution"
}

# # Create CPU Used Chart Graph
# resource "signalfx_time_chart" "cpu_used_chart_graph" {
#   name = "CPU Used %"

#     program_text = <<-EOF
#         A = data('cpu.utilization').publish(label='A')
#         B = alerts(detector_id='${var.det_prom_tags_id[0]}').publish(label='B')       
#         EOF
        
#     plot_type = "LineChart"
#     show_data_markers = true

#     description = "CPU utilisation as a Percentage"
# }

# Create CPU Used Chart Graph
resource "signalfx_time_chart" "cpu_used_chart_graph" {
  name = "CPU Used %"

    program_text = <<-EOF
        A = data('cpu.utilization').publish(label='A')
        EOF
        
    plot_type = "LineChart"
    show_data_markers = true

    description = "CPU utilisation as a Percentage"
}

######################## Host Count Charts ########################

# Create Active Hosts Chart
resource "signalfx_single_value_chart" "active_hosts" {
  name = "Total Hosts"

    program_text = <<-EOF
        A = data('memory.utilization', extrapolation='last_value', maxExtrapolations=5).count().publish(label='A')
        EOF

    description = "Number of running Hosts"
}

# # Create Hosts Above 80 Chart
# resource "signalfx_single_value_chart" "cpu_above_80" {
#   name = "CPU Above 80"

#     program_text = <<-EOF
#         A = data('cpu.utilization').above(80, inclusive=True).count().publish(label='A')
#         B = alerts(detector_id='${var.det_prom_tags_id[0]}').publish(label='B')  
#         EOF

#     description = "Number of Hosts with CPU Greater than 80%"
# }

# Create Hosts Above 80 Chart
resource "signalfx_single_value_chart" "cpu_above_80" {
  name = "CPU Above 80"

    program_text = <<-EOF
        A = data('cpu.utilization').above(80, inclusive=True).count().publish(label='A')
        EOF

    description = "Number of Hosts with CPU Greater than 80%"
}

# Active Collectors Chart
resource "signalfx_single_value_chart" "active_collector_containers" {
  name = "Active Collector Containers"

    program_text = <<-EOF
      A = data('network.usage.tx_bytes', filter=filter('plugin', 'docker') and filter('container_image', '*splunk-otel-collector*')).count().publish(label='A')
      EOF
    description = "Number of Active Collector Containers"
}

# Create MySQL Servers Chart
resource "signalfx_single_value_chart" "active_mysql_servers" {
  name = "Active MySQL Servers"

    program_text = <<-EOF
        A = data('mysql_octets.rx', filter=filter('plugin', 'mysql'), extrapolation='last_value', maxExtrapolations=5).count().publish(label='A')
        EOF

    description = "Number of running MySQL Servers"
}

# Create Apache Servers Chart
resource "signalfx_single_value_chart" "active_apache_servers" {
  name = "Active Apache Servers"

    program_text = <<-EOF
        A = data('apache_requests', filter=filter('plugin', 'apache'), extrapolation='last_value', maxExtrapolations=5).count().publish(label='A')
        EOF

    description = "Number of running Apache Servers"
}

# # Create Nginx Servers Chart
# resource "signalfx_single_value_chart" "nginx_servers0" {
#   name = "Nginx Servers"

#     program_text = <<-EOF
#         A = data('nginx_requests', filter=filter('plugin', 'nginx'), extrapolation='last_value', maxExtrapolations=5).count().publish(label='A')
#         EOF

#     description = "Number of running Nginx Servers"
# }

# Create HAProxy Servers Chart
resource "signalfx_single_value_chart" "active_haproxy_servers" {
  name = "Active HAProxy Servers"

    program_text = <<-EOF
        A = data('ps_data', filter=filter('plugin_instance', 'haproxy')).count().publish(label='A')
        EOF

    description = "Number of running HAProxy Servers"
}

# Create Splunk Servers Chart
resource "signalfx_single_value_chart" "active_splunk_servers" {
  name = "Active Splunk Servers"

    program_text = <<-EOF
        A = data('ps_data', filter=filter('plugin_instance', 'splunkd')).count().publish(label='A')
        EOF

    description = "Number of running Splunk Servers"
}

# # Create Active SmartGateway Chart
# resource "signalfx_single_value_chart" "active_smartgateways0" {
#   name = "Active SmartGateways"

#     program_text = <<-EOF
#         A = data('memory.used', filter('host', 'Smart*'), extrapolation='last_value', maxExtrapolations=5).count().publish(label='A')
#         EOF

#     description = "Number of active SmartGateways"
# }


######################## Disk Space Charts ########################

# Create Disk Space XVDA1 Chart
resource "signalfx_time_chart" "disk_space_xvda10" {
  name = "Disk Space XVDA1"

    program_text = <<-EOF
        A = data('df_complex.free', filter=filter('device', '/dev/xvda1')).publish(label='A')
        EOF

    description = "Disk space of XVDA1"
}

# Create Disk Space XVDG1 Chart
resource "signalfx_time_chart" "disk_space_xvdg10" {
  name = "Disk Space XVDG1"

    program_text = <<-EOF
        A = data('df_complex.free', filter=filter('device', '/dev/xvdg1')).publish(label='A')
        EOF

    description = "Disk space of XVDG1"
}


# Create Write IO XVDA1 Chart
resource "signalfx_time_chart" "write_io_xvda10" {
  name = "Write IO XVDA1"

    program_text = <<-EOF
        A = data('disk_ops.write', filter=filter('plugin_instance', 'xvda1')).publish(label='A')
        EOF

    description = "Write IO for XVDA1"
}

# Create Write IO XVDG1 Chart
resource "signalfx_time_chart" "write_io_xvdg10" {
  name = "Write IO XVDG1"

    program_text = <<-EOF
        A = data('disk_ops.write', filter=filter('plugin_instance', 'xvdg1')).publish(label='A')
        EOF

    description = "Write IO for XVDG1"
}

########################################################################
# # Create xxxxx Chart
# resource "xxxxxx" "xxxxxx" {
#   name = "xxxxxx"

#     program_text = <<-EOF
#         A = xxxxxx
#         EOF

#     description = "xxxxxx"
# }

# # Create xxxxx Chart
# resource "xxxxxx" "xxxxxx" {
#   name = "xxxxxx"

#     program_text = <<-EOF
#         A = xxxxxx
#         EOF

#     description = "xxxxxx"
# }

