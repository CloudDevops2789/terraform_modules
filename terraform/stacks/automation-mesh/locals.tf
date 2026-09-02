locals {
  tags = var.common_tags

  ssh_ingress_rules = var.automation_mesh_enabled ? {
    for index, cidr in sort(tolist(var.ssh_ingress_cidrs)) :
    "ssh-${index}" => {
      type              = "ingress"
      security_group_id = module.execution_node_security_group.security_group_ids["execution-node"]
      description       = "SSH from approved administration source"
      ip_protocol       = "tcp"
      from_port         = 22
      to_port           = 22
      cidr_ipv4         = cidr
    }
  } : {}

  mesh_ingress_rules = var.automation_mesh_enabled ? {
    for index, cidr in sort(tolist(var.mesh_ingress_cidrs)) :
    "mesh-${index}" => {
      type              = "ingress"
      security_group_id = module.execution_node_security_group.security_group_ids["execution-node"]
      description       = "Receptor from approved Automation Mesh peer"
      ip_protocol       = "tcp"
      from_port         = 27199
      to_port           = 27199
      cidr_ipv4         = cidr
    }
  } : {}

  egress_rules = var.automation_mesh_enabled ? {
    for index, cidr in sort(tolist(var.egress_ipv4_cidrs)) :
    "egress-${index}" => {
      type              = "egress"
      security_group_id = module.execution_node_security_group.security_group_ids["execution-node"]
      description       = "Outbound traffic through existing enterprise routing controls"
      ip_protocol       = "-1"
      cidr_ipv4         = cidr
    }
  } : {}
}
