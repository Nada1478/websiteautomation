output "s3_bucket_name" {
  value = aws_s3_bucket.s3terra.id
}

output "s3_website_url" {
  value = aws_s3_bucket_website_configuration.s3terra.website_endpoint
}

output "vpc_id" {
  value = aws_vpc.main.id
}