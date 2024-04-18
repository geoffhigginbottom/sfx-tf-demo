resource "aws_instance" "proxied_windows_server" {
  count                     = var.proxied_windows_server_count
  ami                       = var.windows_server_ami
  instance_type             = var.windows_server_instance_type
  subnet_id                 = element(var.public_subnet_ids, count.index)
  key_name                  = var.key_name
  vpc_security_group_ids    = [aws_security_group.proxied_instances_sg.id]

  user_data = <<EOF
  <powershell>

    Get-LocalUser -Name "Administrator" | Set-LocalUser -Password (ConvertTo-SecureString -AsPlainText "${var.windows_server_administrator_pwd}" -Force)

    [Environment]::SetEnvironmentVariable("http_proxy","http://${aws_instance.proxy_server[0].private_ip}:8080","Machine")
    [Environment]::SetEnvironmentVariable("https_proxy","http://${aws_instance.proxy_server[0].private_ip}:8080","Machine")
    [Environment]::SetEnvironmentVariable("no_proxy","169.254.169.254","Machine")
    netsh winhttp set proxy "${aws_instance.proxy_server[0].private_ip}:8080"

    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -name ProxyServer -Value "http://${aws_instance.proxy_server[0].private_ip}:8080"
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -name ProxyEnable -Value 1

    $source = "https://github.com/signalfx/splunk-otel-collector/releases/download/v${var.collector_version}/splunk-otel-collector-${var.collector_version}-amd64.msi"
    $dest = "C:\Windows\Temp\splunk-otel-collector-${var.collector_version}-amd64.msi"
    $WebClient = New-Object System.Net.WebClient
    $WebProxy = New-Object System.Net.WebProxy("http://${aws_instance.proxy_server[0].private_ip}:8080",$true)
    $WebClient.Proxy = $WebProxy
    $WebClient.DownloadFile($source,$dest)
    Start-Process msiexec.exe -Wait -ArgumentList '/I C:\Windows\Temp\splunk-otel-collector-${var.collector_version}-amd64.msi /quiet'

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
        "SPLUNK_TRACE_URL=https://ingest.${var.realm}.signalfx.com/v2/trace"
    )

    # Check if the registry key exists
    if (Test-Path $registryPath) {
        # Update the registry value
        Set-ItemProperty -Path $registryPath -Name $valueName -Value $newValue -Type MultiString
        Write-Host "Registry value '$valueName' updated successfully."
    } else {
        Write-Host "Registry path '$registryPath' does not exist."
    }

    $source = "${var.windows_proxied_server_agent_url}"
    $dest = "C:\ProgramData\Splunk\OpenTelemetry Collector\agent_config.yaml"
    $WebClient.DownloadFile($source,$dest)
    Start-Service splunk-otel-collector

    Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}' -name IsInstalled -Value 0
    Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}' -name IsInstalled -Value 0

  </powershell>
  
  EOF

  tags = {
    Name = lower(join("-",[var.environment,element(var.proxied_windows_server_ids, count.index)]))
  }
}

output "proxied_windows_server_details" {
  value =  formatlist(
    "%s, %s, %s", 
    aws_instance.proxied_windows_server.*.tags.Name,
    aws_instance.proxied_windows_server.*.public_ip,
    aws_instance.proxied_windows_server.*.public_dns, 
  )
}
