output "zone_id" {
  value = aws_route53_zone.primary.zone_id
}

output "nameservers" {
  value = aws_route53_zone.primary.name_servers
}
