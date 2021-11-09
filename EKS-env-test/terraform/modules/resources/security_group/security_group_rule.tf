resource "aws_security_group_rule" "sg_rule" {
  security_group_id              = aws_security_group.instance_sg.id
  count                          = length(var.sec_group_rules_list)
  type                           = "ingress"
  from_port                      = var.sec_group_rules_list[count.index].from_port
  to_port                        = var.sec_group_rules_list[count.index].to_port
  protocol                       = var.sec_group_rules_list[count.index].protocol
  description                    = var.sec_group_rules_list[count.index].description

  cidr_blocks                    = var.sec_group_rules_list[count.index].cidr_block
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "sg_rule_source_sg" {
  security_group_id              = aws_security_group.instance_sg.id
  count                          = length(var.sec_group_rules_source_sgs)
  type                           = "ingress"
  from_port                      = var.sec_group_rules_source_sgs[count.index].from_port
  to_port                        = var.sec_group_rules_source_sgs[count.index].to_port
  protocol                       = var.sec_group_rules_source_sgs[count.index].protocol
  description                    = var.sec_group_rules_source_sgs[count.index].description

  source_security_group_id       = var.sec_group_rules_source_sgs[count.index].source_security_group_id
  // old syntax element(var.sec_group_rules_list.*.from_port, count.index)
  lifecycle {
    create_before_destroy = true
  }
}

