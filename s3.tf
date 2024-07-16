resource "random_pet" "this" {
  length = 2
}

resource "aws_s3_bucket" "images_bucket" {
  bucket = "images-bucket-${random_pet.this.id}"
  acl    = "private"

  tags = {
    Name        = "images"
    Environment = "production"
  }
}

resource "aws_s3_object" "archive_folder" {
  bucket = aws_s3_bucket.images_bucket.bucket
  key    = "archive/"

  tags = {
    Name        = "archive"
    Environment = "production"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "images_lifecycle" {
  bucket = aws_s3_bucket.images_bucket.bucket

  rule {
    id     = "move-to-glacier"
    status = "Enabled"

    filter {
      prefix = "Memes/"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

resource "aws_s3_bucket" "logs_bucket" {
  bucket = "logs-bucket-${random_pet.this.id}"
  acl    = "private"

  tags = {
    Name        = "logs"
    Environment = "production"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs_lifecycle" {
  bucket = aws_s3_bucket.logs_bucket.bucket

  rule {
    id     = "move-active-to-glacier"
    status = "Enabled"

    filter {
      prefix = "Active/"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }

  rule {
    id     = "delete-inactive"
    status = "Enabled"

    filter {
      prefix = "Inactive/"
    }

    expiration {
      days = 90
    }
  }
}
