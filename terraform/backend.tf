terraform {
  backend "s3" {
    # Parámetros inyectados desde envs/<env>/backend.hcl vía `terraform init -backend-config=`
    # bucket         = "tf-state-p04-..."
    # key            = "p04/terraform.tfstate"
    # region         = "us-east-1"
    # dynamodb_table = "tf-lock-p04"
    # encrypt        = true
  }
}
