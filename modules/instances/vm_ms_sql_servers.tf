resource "aws_instance" "ms_sql" {
  count                     = var.ms_sql_count
  ami                       = var.ms_sql_ami
  instance_type             = var.ms_sql_instance_type
  subnet_id                 = "${var.public_subnet_ids[ count.index % length(var.public_subnet_ids) ]}"
  key_name                  = var.key_name
  vpc_security_group_ids    = [aws_security_group.instances_sg.id]

  user_data = <<EOF
  <powershell>

    Get-LocalUser -Name "Administrator" | Set-LocalUser -Password (ConvertTo-SecureString -AsPlainText "${var.ms_sql_administrator_pwd}" -Force)

    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
    $s = new-object('Microsoft.SqlServer.Management.Smo.Server') localhost
    $nm = $s.Name
    $mode = $s.Settings.LoginMode
    $s.Settings.LoginMode = [Microsoft.SqlServer.Management.SMO.ServerLoginMode] 'Mixed'
    $s.Alter()
    Restart-Service -Name MSSQLSERVER -f

    Invoke-Sqlcmd -Query "CREATE LOGIN [signalfxagent] WITH PASSWORD = '${var.ms_sql_user_pwd}';" -ServerInstance localhost
    Invoke-Sqlcmd -Query "GRANT VIEW SERVER STATE TO [${var.ms_sql_user}];" -ServerInstance localhost
    Invoke-Sqlcmd -Query "GRANT VIEW ANY DEFINITION TO [${var.ms_sql_user}];" -ServerInstance localhost

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
        "SPLUNK_SQL_USER=${var.ms_sql_user}",
        "SPLUNK_SQL_USER_PWD=${var.ms_sql_user_pwd}",
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

    Invoke-WebRequest -Uri ${var.ms_sql_agent_url} -OutFile "C:\ProgramData\Splunk\OpenTelemetry Collector\agent_config.yaml"
    Stop-Service splunk-otel-collector
    Start-Service splunk-otel-collector

    Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}' -name IsInstalled -Value 0
    Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}' -name IsInstalled -Value 0

  </powershell>
  EOF

  tags = {
    Name = lower(join("-",[var.environment, "ms-sql", count.index + 1]))
    Environment = lower(var.environment)
    splunkit_environment_type = "non-prd"
    splunkit_data_classification = "public"
  }
}

output "ms_sql_details" {
  value =  formatlist(
    "%s, %s, %s", 
    aws_instance.ms_sql.*.tags.Name,
    aws_instance.ms_sql.*.public_ip,
    aws_instance.ms_sql.*.public_dns,
    
  )
}
