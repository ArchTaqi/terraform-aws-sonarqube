module "acm" {
  count = var.enable_ssl ? 1 : 0

  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name = var.https_record_domain_name
  zone_id     = var.dns_zone_id

  subject_alternative_names = [
    "*.${var.https_record_domain_name}",
  ]

  create_route53_records = false
  wait_for_validation    = false

  tags = var.tags
}

resource "cloudflare_record" "acm_certificate_records" {
  depends_on = [module.acm]

  for_each = {
    for item in module.acm.acm_certificate_domain_validation_options : item.domain_name => {
      name   = item.resource_record_name
      record = item.resource_record_value
      type   = item.resource_record_type
    }
  }

  zone_id         = var.dns_zone_id
  name            = each.value.name
  type            = each.value.type
  value           = each.value.record
  ttl             = 3600
  priority        = 0
  proxied         = false
  allow_overwrite = true
}
