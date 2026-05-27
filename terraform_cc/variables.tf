
variable "cc_environment_name" {
  description = "NAME of confluent cloud environment to use as displayed in confluent cloud"
  type = string
}

variable "basename" {
  description = "basename for resources, example: gwilliams-flink-medallion"
  type = string
}

# Variables for Elasticsearch connection
variable "elastic_endpoint" {
  description = "Elasticsearch endpoint URL (e.g., https://your-deployment.es.region.cloud.elastic.co:9243)"
  type        = string
}

variable "elastic_api_key" {
  description = "Elasticsearch api key for authentication"
  type        = string
  sensitive   = true
}