# Configure the Confluent Provider
terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version =  "2.73.0"
    }
  }

}

# read from environment variables
provider "confluent" {}



data "confluent_environment" "env" {
  display_name = var.cc_environment_name
}

resource "confluent_kafka_cluster" "cluster" {
  display_name = var.basename
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = "ap-southeast-2"
  basic {}

  environment {
    id = data.confluent_environment.env.id
  }

}

resource "confluent_service_account" "sa" {
  display_name = "${var.basename}-sa"
  description  = "Service Account for ${var.basename}"
}

# basic cluster cannot deal: https://github.com/confluentinc/terraform-provider-confluent/issues/111
resource "confluent_role_binding" "sa-rbac" {
  principal = "User:${confluent_service_account.sa.id}"
  role_name = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.cluster.rbac_crn
}

# KAFKA API key
resource "confluent_api_key" "apikey" {
  display_name = "${var.basename} API Key"
  description  = "API key for ${confluent_service_account.sa.display_name}"
  owner {
    id          = confluent_service_account.sa.id
    api_version = confluent_service_account.sa.api_version
    kind        = confluent_service_account.sa.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.cluster.id
    api_version = confluent_kafka_cluster.cluster.api_version
    kind        = confluent_kafka_cluster.cluster.kind

    environment {
      id = data.confluent_environment.env.id
    }
  }
}






# Flink Compute Pool
resource "confluent_flink_compute_pool" "main" {
  display_name = "${var.basename}-flink-pool"
  cloud        = "AWS"
  region       = "ap-southeast-2"
  max_cfu      = 5
  
  environment {
    id = data.confluent_environment.env.id
  }
}


# add to .env file
output "dot_env" {
  sensitive = true
  value = <<-EOF
    CONNECT_BOOTSTRAP_SERVERS="${confluent_kafka_cluster.cluster.bootstrap_endpoint}"
    CC_API_KEY="${confluent_api_key.apikey.id}"
    CC_API_KEY_SECRET="${confluent_api_key.apikey.secret}"
  EOF
}

