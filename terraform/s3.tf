resource "aws_s3_bucket" "this" {
  bucket_prefix = local.bucket_prefix
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  policy = templatefile("${path.module}/policies/bucket-policy.json", {
    user_arn        = local.user_arn
    account_id      = local.account_id
    bucket_name     = aws_s3_bucket.this.id
    lambda_role_arn = aws_iam_role.lambda.arn
  })
}
