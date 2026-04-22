output "function_name" {
  value = aws_lambda_function.this.function_name
}

output "qualified_arn" {
  description = "ARN con versión, requerido para Lambda@Edge."
  value       = aws_lambda_function.this.qualified_arn
}

output "role_arn" {
  value = aws_iam_role.lambda.arn
}
