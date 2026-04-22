terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws]
    }
    archive = {
      source = "hashicorp/archive"
    }
  }
}

############################################
# Packaging
############################################
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/.terraform-builds/${var.function_name}.zip"
  excludes    = ["tests", "package-lock.json", "__tests__", "*.test.js"]
}

############################################
# IAM role (Lambda@Edge requiere trust con edgelambda.amazonaws.com)
############################################
data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

resource "aws_iam_role_policy_attachment" "basic_exec" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

############################################
# Función + versión publicada
############################################
resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = var.runtime
  memory_size      = var.memory_size
  timeout          = var.timeout
  filename         = data.archive_file.function_zip.output_path
  source_code_hash = data.archive_file.function_zip.output_base64sha256
  publish          = true
}
