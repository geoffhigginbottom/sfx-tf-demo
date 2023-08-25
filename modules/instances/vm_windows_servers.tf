resource "aws_instance" "windows_server" {
  count                     = var.windows_server_count
  ami                       = var.windows_server_ami
  instance_type             = var.windows_server_instance_type
  subnet_id                 = element(var.public_subnet_ids, count.index)
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

    New-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Session Manager\Environment' -Name 'SPLUNK_GATEWAY_URL' -Value ${aws_lb.gateway-lb.dns_name}
   
    Invoke-WebRequest -Uri ${var.windows_server_agent_url} -OutFile "C:\ProgramData\Splunk\OpenTelemetry Collector\agent_config.yaml"
    Stop-Service splunk-otel-collector
    Start-Service splunk-otel-collector

    Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}' -name IsInstalled -Value 0
    Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}' -name IsInstalled -Value 0

  </powershell>
  EOF

  tags = {
    Name = lower(join("-",[var.environment,element(var.windows_server_ids, count.index)]))
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
