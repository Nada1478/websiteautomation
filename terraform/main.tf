resource "aws_vpc" "main" {
  cidr_block       = var.aws_vpc_cider_block
  instance_tenancy = "default"

  tags = {
    Name = "staticwebsitevpc"
  }
}

resource "aws_subnet" "main1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.aws_subnet_cider_block

  tags = {
    Name = "publicsubnet"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "my-igw"
  }
}


resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "PublicRouteTable"
  }
}

 
resource "aws_route" "internet_access_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0" # Directs all internet-bound traffic
  gateway_id             = aws_internet_gateway.my_igw.id # Directs traffic to the IGW
}


resource "aws_route_table_association" "public_rt_association" {
  subnet_id      = aws_subnet.main1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_s3_bucket" "s3terra" {
  bucket = "my-automated-static-website"
  ##website  {
    #index_document = "index.html"
    #error_document = "error.html"
  #}

  tags = {
    Name        = "My bucket static website"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_website_configuration" "s3terra" {
  bucket = aws_s3_bucket.s3terra.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.s3terra.id
  key    = "index.html"
  source = "../website/index.html"
  #acl    = "public-read"
  content_type = "text/html"
}

resource "aws_s3_object" "error" {
  bucket = aws_s3_bucket.s3terra.id
  key    = "error.html"
  source = "../website/error.html"
  #acl    = "public-read"
  content_type = "text/html"
}

# Make bucket public
resource "aws_s3_bucket_public_access_block" "s3terra" {
  bucket = aws_s3_bucket.s3terra.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy for public read - FIXED with depends_on
resource "aws_s3_bucket_policy" "s3terra" {
  bucket = aws_s3_bucket.s3terra.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.s3terra.arn}/*"
      }
    ]
  })
  
  # This ensures the public access block is applied first
  depends_on = [aws_s3_bucket_public_access_block.s3terra]
}