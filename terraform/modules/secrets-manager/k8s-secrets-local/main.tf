terraform {
  required_providers {
    dotenv = {
      source  = "jrhouston/dotenv"
      version = "~> 1.0"
    }
  }
}

data "aws_ssm_parameter" "ssm-local" {
  name      = "/${var.PROJECT_NAME}/${var.ENVIRONMENT}/${var.service_name}-vars-secrets"
  with_decryption   = "true"
}

data dotenv dev_config_local {
  string    = data.aws_ssm_parameter.ssm-local.value
  depends_on  = [ data.aws_ssm_parameter.ssm-local ]
}

resource "kubernetes_secret" "k8s-secret-local" {
  count           = contains(var.PROJECT_SERVICES_LIST, var.service_name) ? 0 : 1
  metadata {
    name      = "${var.PROJECT_NAME}-${var.ENVIRONMENT}-${var.service_name}-vars-secrets"
    namespace = "${var.ENVIRONMENT}"
  }
  data = { for k, v in data.dotenv.dev_config_local.env : k => v }
  type = "kubernetes.io/Opaque"
  depends_on  = [ data.dotenv.dev_config_local ]
}
