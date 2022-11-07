
resource "aws_network_interface" "redisconf-server-nic" {
  subnet_id   = aws_subnet.private_subnet.id
  private_ips = ["10.0.1.50"]
}

resource "aws_instance" "ec2_redis" {
  ami                         = data.aws_ami.server_ami.id
  instance_type               = "t2.micro"
  availability_zone           = "us-east-1a"
  associate_public_ip_address = false
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.redisconf-server-nic.id
  }

  tags = {
    "Name" = "Redis-EC2-private"
  }
}

data "rediscloud_payment_method" "card" {
  card_type         = "Visa"
  last_four_numbers = var.cc_last_4
}

# Generetes a random password for the database
resource "random_password" "passwords" {
  count   = 2
  length  = 20
  upper   = true
  lower   = true
  numeric = true
  special = false
}

resource "rediscloud_subscription" "redis-sub" {
  name              = "redisconf-Test"
  payment_method_id = data.rediscloud_payment_method.card.id
  memory_storage    = "ram"

  cloud_provider {
    # Running in Aws on Redis Labs resources
    provider         = "AWS"
    cloud_account_id = var.rediscloud_account_id

    region {
      region                       = "us-east-1"
      networking_deployment_cidr   = "192.168.1.0/24"
      preferred_availability_zones = ["us-east-1a"]
    }
  }
  database {
    name                         = "redis-db"
    protocol                     = "redis"
    memory_limit_in_gb           = 1
    replication                  = true
    data_persistence             = "none"
    throughput_measurement_by    = "operations-per-second"
    throughput_measurement_value = 26000
    password                     = random_password.passwords[0].result
  }
  database {
    name               = "redis-db-json"
    protocol           = "redis"
    memory_limit_in_gb = 1
    replication        = true
    data_persistence   = "aof-every-1-second"
    module {
      name = "RedisJSON"
    }
    throughput_measurement_by    = "operations-per-second"
    throughput_measurement_value = 10000
    password                     = random_password.passwords[1].result
  }
}

resource "rediscloud_subscription_peering" "redis-sub-peering" {
  subscription_id = rediscloud_subscription.redis-sub.id
  region          = "us-east-1"
  aws_account_id  = var.aws_account_id
  vpc_id          = aws_vpc.main.id
  vpc_cidr        = aws_vpc.main.cidr_block

}

resource "aws_vpc_peering_connection_accepter" "aws-peering" {
  vpc_peering_connection_id = rediscloud_subscription_peering.redis-sub-peering.aws_peering_id
  auto_accept               = true
}