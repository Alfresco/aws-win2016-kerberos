output "kerberos-domain" {
  value = "${var.DOMAIN}.${var.HOSTED_ZONE}"
}

output "kerberos-server-public-ip" {
  value = "${aws_instance.kerberos-server.public_ip}"
}

output "kerberos-client-public-ip" {
  value = "${aws_instance.kerberos-client.public_ip}"
}

output "kerberos-server-admin-username" {
  value = "${var.SERVER_ADMIN_USERNAME}"
}
output "kerberos-server-admin-password" {
  value = "${var.SERVER_ADMIN_PASSWORD}"
}

output "kerberos-client-test-username" {
  value = "${var.KERBEROS_TEST_USERNAME}@${var.DOMAIN}.${var.HOSTED_ZONE}"
}
output "kerberos-client-test-password" {
  value = "${var.KERBEROS_TEST_PASSWORD}"
}
