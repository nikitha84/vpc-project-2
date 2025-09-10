resource "aws_vpc_peering_connection" "peering" {
  count = var.is_peering_required ? 1 : 0 # using count condition we can restrict peering 
  vpc_id        = aws_vpc.roboshop_vpc.id #requester vpc
  peer_vpc_id = var.acceptor_vpc_id == "" ? data.aws_vpc.default.id : var.acceptor_vpc_id #pacceptor vpc if acceptor not give vpc take default vpc id using conditions
  auto_accept = var.acceptor_vpc_id == "" ? true : false #if default vpc it our control
  tags = merge(
    var.common_tags,
    var.vpc_peering_tags,
    {
      Name = "${local.name}"
    }

  )

}

resource "aws_route" "acceptor_route" {  #adding acceptor route
  count = var.is_peering_required && var.acceptor_vpc_id == "" ? 1 : 0 #if acceptor vpc empty
  route_table_id            = data.aws_route_table.default.id
  destination_cidr_block    = var.vpc_cidr  #roboshop vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
 
}


resource "aws_route" "public_peering" {  #adding acceptor route
  count = var.is_peering_required && var.acceptor_vpc_id == "" ? 1 : 0 #if acceptor vpc empty
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = data.aws_vpc.default.cidr_block #default vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
  
}
resource "aws_route" "private_peering" {  
  count = var.is_peering_required && var.acceptor_vpc_id == "" ? 1 : 0 
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = data.aws_vpc.default.cidr_block #default vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
  
}
