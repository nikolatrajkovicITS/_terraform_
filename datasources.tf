# we need to provide the AMI from which we want to deploy our infrastracture.
# data source is just a query of the AWS API to receive information needed to deploy a resource.
data "aws_ami" "server_ami" {
  most_recent = true
  // owner id of ami
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}