##################################################################################################
# AWS Managed Microsoft AD Client Network Rules
##################################################################################################
#
# AWS creates and owns the directory security group. These additive rules permit
# only caller-approved client networks to use native Active Directory services.
#
##################################################################################################

locals {
  managed_ad_client_ingress_services = {
    dns_tcp = {
      protocol  = "tcp"
      from_port = 53
      to_port   = 53
      service   = "DNS"
    }
    dns_udp = {
      protocol  = "udp"
      from_port = 53
      to_port   = 53
      service   = "DNS"
    }
    kerberos_tcp = {
      protocol  = "tcp"
      from_port = 88
      to_port   = 88
      service   = "Kerberos"
    }
    kerberos_udp = {
      protocol  = "udp"
      from_port = 88
      to_port   = 88
      service   = "Kerberos"
    }
    ntp_udp = {
      protocol  = "udp"
      from_port = 123
      to_port   = 123
      service   = "NTP"
    }
    rpc_endpoint_mapper_tcp = {
      protocol  = "tcp"
      from_port = 135
      to_port   = 135
      service   = "RPC endpoint mapper"
    }
    ldap_tcp = {
      protocol  = "tcp"
      from_port = 389
      to_port   = 389
      service   = "LDAP"
    }
    ldap_udp = {
      protocol  = "udp"
      from_port = 389
      to_port   = 389
      service   = "LDAP"
    }
    smb_tcp = {
      protocol  = "tcp"
      from_port = 445
      to_port   = 445
      service   = "SMB"
    }
    kerberos_password_tcp = {
      protocol  = "tcp"
      from_port = 464
      to_port   = 464
      service   = "Kerberos password"
    }
    kerberos_password_udp = {
      protocol  = "udp"
      from_port = 464
      to_port   = 464
      service   = "Kerberos password"
    }
    ldaps_tcp = {
      protocol  = "tcp"
      from_port = 636
      to_port   = 636
      service   = "LDAPS"
    }
    global_catalog_tcp = {
      protocol  = "tcp"
      from_port = 3268
      to_port   = 3268
      service   = "Global Catalog"
    }
    global_catalog_tls_tcp = {
      protocol  = "tcp"
      from_port = 3269
      to_port   = 3269
      service   = "Global Catalog TLS"
    }
    rpc_dynamic_tcp = {
      protocol  = "tcp"
      from_port = 49152
      to_port   = 65535
      service   = "RPC dynamic ports"
    }
  }

  managed_ad_client_ingress_rules = {
    for rule in flatten([
      for cidr in sort(tolist(var.client_cidr_blocks)) : [
        for service_key, service in local.managed_ad_client_ingress_services : {
          key      = "${replace(replace(cidr, ".", "-"), "/", "-")}-${service_key}"
          cidr     = cidr
          protocol = service.protocol
          from     = service.from_port
          to       = service.to_port
          service  = service.service
        }
      ]
    ]) :
    rule.key => rule
  }
}

resource "aws_vpc_security_group_ingress_rule" "client" {
  for_each = local.managed_ad_client_ingress_rules

  security_group_id = aws_directory_service_directory.this.security_group_id
  cidr_ipv4         = each.value.cidr
  ip_protocol       = each.value.protocol
  from_port         = each.value.from
  to_port           = each.value.to

  description = "Managed AD ${each.value.service} from approved client network"

  tags = var.tags
}
