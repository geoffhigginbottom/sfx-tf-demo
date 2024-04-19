resource "aws_instance" "windows_server" {
  count                     = var.windows_server_count
  ami                       = var.windows_server_ami
  instance_type             = var.windows_server_instance_type
  subnet_id                 = "${var.public_subnet_ids[ count.index % length(var.public_subnet_ids) ]}"
  key_name                  = var.key_name
  vpc_security_group_ids    = [aws_security_group.instances_sg.id]

  user_data = <<EOF
  <powershell>

    Get-LocalUser -Name "Administrator" | Set-LocalUser -Password (ConvertTo-SecureString -AsPlainText "${var.windows_server_administrator_pwd}" -Force)

	  & {Set-ExecutionPolicy Bypass -Scope Process -Force;
    $script = ((New-Object System.Net.WebClient).DownloadString('https://dl.signalfx.com/splunk-otel-collector.ps1'));
    $params = @{access_token = "${var.access_token}";
    realm = "${var.realm}";
    mode = "agent"};
    Invoke-Command -ScriptBlock ([scriptblock]::Create(". {$script} $(&{$args} @params)"))}
   
    $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\splunk-otel-collector"
    $valueName = "Environment"
    $newValue = @(
        "SPLUNK_ACCESS_TOKEN=${var.access_token}",
        "SPLUNK_API_URL=https://api.${var.realm}.signalfx.com",
        "SPLUNK_BUNDLE_DIR=C:\Program Files\Splunk\OpenTelemetry Collector\agent-bundle",
        "SPLUNK_CONFIG=C:\ProgramData\Splunk\OpenTelemetry Collector\agent_config.yaml",
        "SPLUNK_HEC_TOKEN=${var.access_token}",
        "SPLUNK_HEC_URL=https://ingest.${var.realm}.signalfx.com/v1/log",
        "SPLUNK_INGEST_URL=https://ingest.${var.realm}.signalfx.com",
        "SPLUNK_REALM=${var.realm}",
        "SPLUNK_TRACE_URL=https://ingest.${var.realm}.signalfx.com/v2/trace",
        "SPLUNK_GATEWAY_URL=${aws_lb.gateway-lb.dns_name}"
    )

    # Check if the registry key exists
    if (Test-Path $registryPath) {
        # Update the registry value
        Set-ItemProperty -Path $registryPath -Name $valueName -Value $newValue -Type MultiString
        Write-Host "Registry value '$valueName' updated successfully."
    } else {
        Write-Host "Registry path '$registryPath' does not exist."
    }

    Invoke-WebRequest -Uri ${var.windows_server_agent_url} -OutFile "C:\ProgramData\Splunk\OpenTelemetry Collector\agent_config.yaml"
    Stop-Service splunk-otel-collector
    Start-Service splunk-otel-collector

    Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}' -name IsInstalled -Value 0
    Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}' -name IsInstalled -Value 0

  </powershell>
  EOF

  tags = {
    Name = lower(join("-",[var.environment, "windows", count.index + 1]))
    Environment = lower(var.environment)
    splunkit_environment_type = "non-prd"
    splunkit_data_classification = "public"
  }
}

output "windows_server_details" {
  value =  formatlist(
    "%s, %s, %s", 
    aws_instance.windows_server.*.tags.Name,
    aws_instance.windows_server.*.public_ip,
    aws_instance.windows_server.*.public_dns, 
  )
}
