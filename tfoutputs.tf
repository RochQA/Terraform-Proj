output "ipaddress_of_server" {
  value = "${aws_instance.web-1.public_ip}"
}
output "dns_of_server" {
  value = "${aws_instance.web-1.public_dns}"
}