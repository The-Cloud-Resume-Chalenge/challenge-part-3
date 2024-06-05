resource "aws_s3_bucket" "majid" {
  bucket        = var.dns
  provider      = aws.abd
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  provider = aws.abd
  bucket = aws_s3_bucket.majid.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_website_configuration" "blog" {
  provider = aws.abd
  bucket   = aws_s3_bucket.majid.id
  index_document {
    suffix = var.index_document
  }
  error_document {
    key = var.error_document
  }
}


resource "aws_s3_bucket_public_access_block" "public_access_block" {
  provider                = aws.abd
  bucket                  = aws_s3_bucket.majid.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket   = aws_s3_bucket.majid.id
  provider = aws.abd
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "s3:GetObject",
        "Resource" : "${aws_s3_bucket.majid.arn}/*"
      }
    ]
  })
}



resource "aws_s3_object" "provision_source_files" {
  provider = aws.abd
  bucket   = aws_s3_bucket.majid.id
  for_each = fileset("html/", "*.{html,css,jpg,png,js}")
  key = each.value

  source = "html/${each.value}"

  content_type = try(
    {
      "html" = "text/html",
      "css"  = "text/css",
      "jpg"  = "image/jpeg",
      "png"  = "image/png",
      "js"   = "application/javascript"
    }[split(".", each.value)[length(split(".", each.value)) - 1]],
    "application/octet-stream"
  )

  depends_on = [
    null_resource.update_index_js
  ]
}