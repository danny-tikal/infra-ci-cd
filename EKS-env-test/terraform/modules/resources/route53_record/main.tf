resource "aws_route53_record" "record" {
  
  zone_id = var.zone_id
  name    = var.cname
  type    = var.type
  ttl     = var.ttl
  records = [var.record]

}