#creting vpc
resource "aws_vpc" "mukesh-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "mike-vpc"
  }
}

#adding public subnet
resource "aws_subnet" "web-base" {
  vpc_id     = aws_vpc.mukesh-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "mike-public"
  }
}

#adding private subet
resource "aws_subnet" "data-base" {
  vpc_id     = aws_vpc.mukesh-vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "mike-private"
  }
}

#security group
resource "aws_security_group" "mukesh-sg" {
  name        = "mike-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.mukesh-vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "mike-sg"
  }
}

#internet gtw
resource "aws_internet_gateway" "mike-gw" {
  vpc_id = aws_vpc.mukesh-vpc.id

  tags = {
    Name = "mike-gw"
  }
}

#route table public
resource "aws_route_table" "mike-rt" {
  vpc_id = aws_vpc.mukesh-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mike-gw.id
  }

  tags = {
    Name = "mike-pubrt"
  }
}

#route table association
resource "aws_route_table_association" "mike-association" {
  subnet_id      = aws_subnet.web-base.id
  route_table_id = aws_route_table.mike-rt.id
}

#key pair
resource "aws_key_pair" "mukeshkey" {
  key_name   = "mukeshkey"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDJAZI4z3HHbgBNdIphLYckheEUI4YaQnnrsZFdEoc4DydBNYceulrIkfT1RzHXBbpXchZvbP6qcVCyuw5PnbLkIJNVGrzUJI+38mDmGBPm/eQkPC1COnr9HeaqsGHGx/dwshWNHii6NN8gLh5Kycd2PdPzzCVAQAEQjUNgsKKfgfBRgMibbyM6kxtnJpqaakCJwomP5WWzKAdvx8llEXCWV9cAEiTkK6gD3/ViuAv5TZwFovuQZXqxXo6IaJwORQoQJPtLFU7YfNBiGvi1E+snyfdkeN4Ssd2TQHtOsD3tAisxafYzUTF4vWRvgU6KLufzet2U2A60az8OfGCKAzqRzpyiCQUolAsRDSJs446Nr1CQJ/PpmCaHFS5X50QiXP4dgdZwHj2RSY0GEIRhyZvZK7XmAVUHfB/pcqksDDapuvCqtwv0aUfdyKi9EZqBbex4oBKFOnNpFE9RMtprasITWeUlHBR3gXln91tl/Cg5Q20TukpF+NLh+dwSxAVimMs= Dell@DESKTOP-8ISR31S"
}

#ec2 instance
resource "aws_instance" "mukesh-webserver" {
  ami           = "ami-00874d747dde814fa"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.web-base.id
  vpc_security_group_ids = [aws_security_group.mukesh-sg.id]
  key_name = "mukeshkey"

  tags = {
    Name = "webserver"
  }
}

#dataserver
resource "aws_instance" "mukesh-dataserver" {
  ami           = "ami-00874d747dde814fa"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.data-base.id
  vpc_security_group_ids = [aws_security_group.mukesh-sg.id]
  key_name = "mukeshkey"

  tags = {
    Name = "dataserver"
  }
}

#add elastic ip
resource "aws_eip" "mike-eip" {
  instance = aws_instance.mukesh-webserver.id
  vpc      = true
}

#add nat elastic ip
resource "aws_eip" "mike-eip-nat" {
  vpc      = true
}

#nat gtw
resource "aws_nat_gateway" "mike-nat" {
  allocation_id = aws_eip.mike-eip-nat.id
  subnet_id     = aws_subnet.web-base.id

  tags = {
    Name = "mike-nat"
  }
}

#database route table
resource "aws_route_table" "mike-drt" {
  vpc_id = aws_vpc.mukesh-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.mike-nat.id
  }

  tags = {
    Name = "mike-dbnat"
  }
}

#database route table association
resource "aws_route_table_association" "mike-database-association" {
  subnet_id      = aws_subnet.data-base.id
  route_table_id = aws_route_table.mike-drt.id
}



