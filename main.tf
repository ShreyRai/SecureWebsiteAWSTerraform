resource "aws_vpc" "website1-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    name = "website1-vpc"
  }
}

resource "aws_subnet" "Public-subnet" {
  vpc_id     = aws_vpc.website1-vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-subnet-web1"
  }
}

resource "aws_subnet" "Private-subnet" {
  vpc_id     = aws_vpc.website1-vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Private-subnet-web1"
  }
}

resource "aws_internet_gateway" "website1-igw" {
  vpc_id = aws_vpc.website1-vpc.id

  tags = {
    Name = "website1-igw"
  }
}

resource "aws_route_table" "website1-rt" {
  vpc_id = aws_vpc.website1-vpc.id

}

resource "aws_route" "website1-r"{
    route_table_id = aws_route_table.website1-rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.website1-igw.id
}

resource "aws_route_table_association" "website1-asa"{
    subnet_id = aws_subnet.Public-subnet.id
    route_table_id = aws_route_table.website1-rt.id 
}

resource "tls_private_key" "website1-ec2-key" {
  algorithm = "RSA"
  rsa_bits = 2048
}

resource "aws_key_pair" "web1-ec2-key" {
  key_name = "Website1-ec2-key-pair"
  public_key = tls_private_key.website1-ec2-key.public_key_openssh
  
}

resource "local_file" "website1key" {
  content = tls_private_key.website1-ec2-key.private_key_pem
  filename = "${path.module}/mykeys/Website1-ec2-key-pair.pem"
  file_permission = 0400
}

resource "aws_instance" "website1-ec2"{
  ami = var.ami
  instance_type = "t2.micro"
  subnet_id = aws_subnet.Public-subnet.id
  key_name = aws_key_pair.web1-ec2-key.key_name
  
  #vpc_security_group_ids = [aws_security_group.website1-sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  #security_groups = [aws_security_group.website1-sg.id]
  tags = {
    Name = "website1-ec2"
  }
  associate_public_ip_address = true
  user_data = <<EOF
  #!/bin/bash
  sudo yum update -y
  sudo yum install -y python3
  sudo yum install -y python3 pip3
  pip3 install flask
  mkdir ~/myapp && cd ~/myapp
  touch app.py
  EOF
}

# Read the content from file1.txt
data "local_file" "file_content" {
  filename = "${path.module}/src/python/app.py" # Path to your local file
}

# Provisioner to create app.py and write content from file1.txt
resource "null_resource" "write_app" {
  depends_on = [aws_instance.website1-ec2]

  provisioner "remote-exec" {
    inline = [
      "echo '${data.local_file.file_content.content}' > app.py",  # This will create app.py
      "chmod +x app.py" # Make the app.py executable if needed
    ]

    
    connection {
      type        = "ssh"
      host        = aws_instance.website1-ec2.public_ip
      user        = "ec2-user" # Change if using a different user
      private_key = local_file.website1key.content # Path to your private key file
  }
}
}
data "http" "my_public_ip" {
  url = "https://api.ipify.org?format=text"
}

resource "aws_security_group" "website1-sg" {
  name   = "website1-sg"
  vpc_id = aws_vpc.website1-vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${chomp(data.http.my_public_ip.response_body)}/32"]
  }
  
  ingress {
    from_port = 5000
    to_port = 5000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [aws_instance.website1-ec2]

}

/*resource "aws_network_interface" "website1-ec2-sg-attach" {
  subnet_id = aws_subnet.Public-subnet.id
  security_groups = [aws_security_group.website1-sg.id]
  attachment {
    instance = aws_instance.website1-ec2.id
    device_index = 0 #0 means primary interface
  }
}*/

resource "aws_vpc_endpoint" "website1-end" {
  vpc_id = aws_vpc.website1-vpc.id
  service_name = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [ aws_route_table.website1-rt.id ]
  tags = {
    name = "s3-endpoint"
  }
  
}

resource "aws_network_interface" "website1-ec2-secondary" {
  subnet_id   = aws_subnet.Public-subnet.id
  security_groups = [aws_security_group.website1-sg.id]  # Attach your security group
}

resource "aws_network_interface_attachment" "website1-ec2-secondary-interface" {
  instance_id          = aws_instance.website1-ec2.id
  network_interface_id = aws_network_interface.website1-ec2-secondary.id
  device_index         = 1  # Use a different device index for additional interfaces
}


resource "aws_s3_bucket" "website1-bucket" {
  bucket = "my-website1-bucket-a1"
  tags = {
    Name        = "my-website1-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "website1-publicblock" {
  bucket = aws_s3_bucket.website1-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

/*resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.website1-bucket.id
  policy = <<POLICY
  {
    "Version": "2012-10-17"
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::my-website1-bucket"
      }
    ]
  }
  POLICY
}*/

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.website1-bucket.id
  policy = data.aws_iam_policy_document.allow_public_access.json
}

data "aws_iam_policy_document" "allow_public_access" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]  # "*" represents public access
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::my-website1-bucket-a1",       # The bucket itself
      "arn:aws:s3:::my-website1-bucket-a1/*",     # All objects inside the bucket
    ]
  }
}


/*resource "aws_s3_bucket_acl" "mys3-acl" {
  depends_on = [
    #aws_s3_bucket_ownership_controls.mys3-ownership,
    aws_s3_bucket_policy.allow_access_from_another_account,
    aws_s3_bucket_public_access_block.website1-publicblock,
  ]

  bucket = aws_s3_bucket.website1-bucket.id
  acl    = "public-read"
}*/

resource "aws_s3_object" "website1-s3-obj1" {
  bucket = aws_s3_bucket.website1-bucket.id
  key    = "akatsuki.html"
  source = "akatsuki.html"
}

resource "aws_s3_object" "website1-s3-obj2" {
  bucket = aws_s3_bucket.website1-bucket.id
  key    = "error.html"
  source = "error.html"
}

resource "aws_s3_bucket_website_configuration" "mys3web1" {
  bucket = aws_s3_bucket.website1-bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
  #depends_on = [ aws_s3_bucket_acl.mys3-acl ]
}

# Step 1: Create IAM Role for EC2 to access S3 with read-only access
resource "aws_iam_role" "ec2_s3_readonly_role" {
  name = "ec2-s3-readonly-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"  # EC2 is the trusted entity
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

# Step 2: Attach the AmazonS3ReadOnlyAccess policy to the IAM Role
resource "aws_iam_role_policy_attachment" "ec2_s3_readonly_attach" {
  role       = aws_iam_role.ec2_s3_readonly_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"  # Predefined AWS policy for S3 read-only access
}

# Step 3: Create an Instance Profile to attach the role to an EC2 instance
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_s3_readonly_role.name
}

