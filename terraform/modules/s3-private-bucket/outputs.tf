output "name" {
  description = "Name of the private S3 bucket."
  value       = aws_s3_bucket.this.bucket
}

output "arn" {
  description = "ARN of the private S3 bucket."
  value       = aws_s3_bucket.this.arn
}

output "id" {
  description = "ID of the private S3 bucket."
  value       = aws_s3_bucket.this.id
}
