resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = var.enable_dns_hostnames
    tags = merge(var.common_tags,
            var.vpc_tags,
            {
                Name = local.name
            }
    )
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
    tags = merge(var.common_tags,
            var.igw_tags,
            {
                Name = local.name
            }
    )
}

resource "aws_eip" "eip" {
    domain   = "vpc"
}
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public[0].id # keep in 1a public-subnet 

  tags = merge(
    var.common_tags,
    var.nat_gateway_tags,
    {
        Name = "${local.name}"
    }
  )
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_subnet" "public" {
    count = length(var.public_subnet_cidr)
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidr[count.index]
    availability_zone = local.az_names[count.index]
    tags = merge(var.common_tags,
            var.public_subnet_tags,
            {
                Name = "${local.name}-${local.az_names[count.index]}"
            }
    )
}
resource "aws_subnet" "private" {
    count = length(var.private_subnet_cidr)
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_cidr[count.index]
    availability_zone = local.az_names[count.index]
    tags = merge(var.common_tags,
            var.private_subnet_tags,
            {
                Name = "${local.name}-${local.az_names[count.index]}"
            }
    )
}
resource "aws_subnet" "database" {
    count = length(var.database_subnet_cidr)
    vpc_id = aws_vpc.main.id
    cidr_block = var.database_subnet_cidr[count.index]
    availability_zone = local.az_names[count.index]
    tags = merge(var.common_tags,
            var.database_subnet_tags,
            {
                Name = "${local.name}-${local.az_names[count.index]}"
            }
    )
}


resource "aws_db_subnet_group" "default" {
  name       = "${local.name}" 
  subnet_ids = aws_subnet.database[*].id

  tags = {
    Name = "${local.name}"
  }
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id
    tags = merge(
        var.common_tags,
        var.public_route_table_tags,
        {
            Name = local.name
        }
    )
}
resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id
    tags = merge(
        var.common_tags,
        var.private_route_table_tags,
        {
            Name = local.name
        }
    )
}
resource "aws_route_table" "database" {
    vpc_id = aws_vpc.main.id
    tags = merge(
        var.common_tags,
        var.database_route_table_tags,
        {
            Name = local.name
        }
    )
}
resource "aws_route" "public_route" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0" #internet
  gateway_id = aws_internet_gateway.igw.id
 
}
resource "aws_route" "private_route" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0" #internet
  nat_gateway_id = aws_nat_gateway.nat.id
  
}
resource "aws_route" "database_route" {
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = "0.0.0.0/0" #internet
  nat_gateway_id = aws_nat_gateway.nat.id
}
resource "aws_route_table_association" "public" { #routes association to subnets
    count = length(var.public_subnet_cidr) #we have 2 subnet(1a,1b)
  subnet_id      = element(aws_subnet.public[*].id, count.index) #sub id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" { #routes association to subnets
    count = length(var.private_subnet_cidr) #we have 2 subnet(1a,1b)
  subnet_id      = element(aws_subnet.private[*].id, count.index) #sub id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database" { #routes association to subnets
    count = length(var.database_subnet_cidr) #we have 2 subnet(1a,1b)
  subnet_id      = element(aws_subnet.database[*].id, count.index) #sub id
  route_table_id = aws_route_table.database.id
}