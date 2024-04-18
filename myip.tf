data "http" "my_public_ip" {
  url = "https://ipv4.icanhazip.com/"
}

output "my_ip_addr" {
  value = "${chomp(data.http.my_public_ip.response_body)}"
}