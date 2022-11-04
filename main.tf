resource "aws_vpc" "main" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "public_subnet" {
  depends_on = [
    aws_vpc.main
  ]

  vpc_id = aws_vpc.main.id

  # IP Range of this subnet
  cidr_block = "192.168.0.0/24"

  # Enabling automatic public IP assignment on instance launch!
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = {
    Name = "dev-public-subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  depends_on = [
    aws_vpc.main,
    aws_subnet.public_subnet
  ]

  # VPC in which subnet has to be created!
  vpc_id = aws_vpc.main.id

  # IP Range of this subnet
  cidr_block = "192.168.1.0/24"

  # Data Center of this subnet.
  availability_zone = "us-east-1b"

  tags = {
    Name = "Private Subnet"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "dev-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "dev_public_rt"
  }
}

# default route for all the traffic to get to the internet
resource "aws_route" "default_route" {
  route_table_id = aws_route_table.public_rt.id
  # all IP addreses will head to this internet gateway
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

resource "aws_route_table_association" "public_association_table" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# we don't need a tag here cus sg has name attribute
resource "aws_security_group" "security_group" {
  name        = "dev_security_group"
  description = "dev security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # added my IP address
    # /32 means that just this adress can be used
    # we can add more IP addreses here
    cidr_blocks = ["94.189.236.40/32"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # we gonna allow wharever goes into this subnet to access anything
    # so we wont put our IP address here this time
    # we allow it to access open internet
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_route_table" "private_subnet_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Local Route Table for Isolated Private Subnet"
  }
}

resource "aws_route_table_association" "private_subnet_rt_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_subnet_rt.id
}

# to be able to deploy our infrastrcuture
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("~/.ssh/terrafrom-tut-key.pub")
}

resource "aws_instance" "dev_node" {
  instance_type = "t2.micro"

  # give this instace ami from which should be deployed
  ami = data.aws_ami.server_ami.id

  # give this instance auth key to be able to deploy
  key_name = aws_key_pair.deployer.key_name

  # give this instance a security group
  vpc_security_group_ids = [aws_security_group.security_group.id]

  # put this instance in this subnet 
  subnet_id = aws_subnet.public_subnet.id

  # add userdata script th the instance
  # user_data will be used to bootstrap our instance
  # in terrform plan user_data will be presented as string-hash
  user_data = file("./userdata.tpl")

  # if we want to resize the defualt size of the drive on this instace
  root_block_device {
    # default size is 8
    volume_size = 10
  }

  # adding local-exec provisiner to instance
  provisioner "local-exec" {

    # command is gonna be run by template file linux-ssh-config.tpl
    command = templatefile("${var.host_os}-ssh-config.tpl", {

      # we have public_ip attribute for instance 
      hostname = self.public_ip,

      # ubuntu is the EC2 instance username
      user = "ubuntu"

      # identityfile gonna be private key
      identityfile = "~/.ssh/terrafrom-tut-key"

      # we need to pass interpreter that tells the our provisioner 
      # what it needs to use to run this script
      interpreter = [var.host_os == "linux" ? ["bash", "-c"] : ["Powershell", "-Command"]]
    })
  }

  tags = {
    Name = "dev-node"
  }
}

// Configure the EC2 instance in a private subnet
resource "aws_instance" "ec2_private_backend" {
  ami                         = data.aws_ami.server_ami.id
  associate_public_ip_address = false
  instance_type               = "t2.micro"
  subnet_id = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.security_group.id]

  tags = {
    "Name" = "Backend-EC2-private"
  }
}

resource "aws_instance" "ec2_private_redis" {
  ami                         = data.aws_ami.server_ami.id
  associate_public_ip_address = false
  instance_type               = "t2.micro"
  subnet_id = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.security_group.id]

  tags = {
    "Name" = "Redis-EC2-private"
  }
}

resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = "GameScores"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "UserId"
  range_key      = "GameTitle"

  attribute {
    name = "UserId"
    type = "S"
  }

  attribute {
    name = "GameTitle"
    type = "S"
  }

  attribute {
    name = "TopScore"
    type = "N"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = false
  }

  global_secondary_index {
    name               = "GameTitleIndex"
    hash_key           = "GameTitle"
    range_key          = "TopScore"
    write_capacity     = 10
    read_capacity      = 10
    projection_type    = "INCLUDE"
    non_key_attributes = ["UserId"]
  }

  tags = {
    Name        = "dynamodb-table-1"
    Environment = "production"
  }
}


# resource "aws_instance" "backend_private_instace" {
#   instance_type = "t2.micro"

#   # give this instace ami from which should be deployed
#   ami = data.aws_ami.server_ami.id

#   # give this instance auth key to be able to deploy
#   key_name = aws_key_pair.deployer.key_name

#   # give this instance a security group
#   vpc_security_group_ids = [aws_security_group.security_group.id]

#   # put this instance in this subnet 
#   subnet_id = aws_subnet.private_subnet.id

#   # add userdata script th the instance
#   # user_data will be used to bootstrap our instance
#   # in terrform plan user_data will be presented as string-hash
#   user_data = file("./userdata.tpl")

#   # if we want to resize the defualt size of the drive on this instace
#   root_block_device {
#     # default size is 8
#     volume_size = 10
#   }

#   # adding local-exec provisiner to instance
#   provisioner "local-exec" {

#     # command is gonna be run by template file linux-ssh-config.tpl
#     command = templatefile("${var.host_os}-ssh-config.tpl", {

#       # we have privite_ip attribute for instance 
#       hostname = self.privite_ip,

#       # ubuntu is the EC2 instance username
#       user = "ubuntu"

#       # identityfile gonna be private key
#       identityfile = "~/.ssh/terrafrom-tut-key"

#       # we need to pass interpreter that tells the our provisioner 
#       # what it needs to use to run this script
#       interpreter = [var.host_os == "linux" ? ["bash", "-c"] : ["Powershell", "-Command"]]
#     })
#   }

#     tags = {
#     Name = "dev-node-private-instance"
#   }
# }