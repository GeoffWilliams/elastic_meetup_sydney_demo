

# Elasticsearch Sink Connector for PLAINTEXT JSON
resource "confluent_connector" "elasticsearch_sink_A" {
  environment {
    id = data.confluent_environment.env.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }

  config_sensitive = {
    "connection.url"      = var.elastic_endpoint
    "api.key.value"       = var.elastic_api_key
  }

  config_nonsensitive = {
    "name"                     = "TBA_local_info_1"
    "connector.class"          = "ElasticsearchSinkV2"

    "kafka.auth.mode"          = "KAFKA_API_KEY",
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = confluent_service_account.sa.id
    
    "topics"                   = "hotel_inventory,transport_availability,flight_schedule"

    "input.data.format"        = "JSON"
    
    "resource.type"            = "INDEX",
    "auto.create"              = "true",
    "key.ignore"               = "true",
    
    "tasks.max"                = 1,
    "auth.type"                = "API_KEY",
    
    # vital...
    "elastic.server.version"   = "V9",
  }

  depends_on = [
    confluent_kafka_topic.irops_events,
    confluent_role_binding.sa-rbac
  ]
}

# Elasticsearch Sink Connector for JSON SCHEMA
resource "confluent_connector" "elasticsearch_sink_B" {
  environment {
    id = data.confluent_environment.env.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }

  config_sensitive = {
    "connection.url"      = var.elastic_endpoint
    "api.key.value"       = var.elastic_api_key
  }

  config_nonsensitive = {
    "name"                     = "TBA_flink_outputs"
    "connector.class"          = "ElasticsearchSinkV2"

    "kafka.auth.mode"          = "KAFKA_API_KEY",
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = confluent_service_account.sa.id
    
    "topics"                   = "enriched_irops_events,flight_performance_summary"

    "input.data.format"        = "JSON_SR"
    
    "resource.type"            = "INDEX",
    "auto.create"              = "true",
    "key.ignore"               = "true",
    
    "tasks.max"                = 1,
    "auth.type"                = "API_KEY",
    
    # vital...
    "elastic.server.version"   = "V9",
  }

  depends_on = [
    confluent_kafka_topic.irops_events,
    confluent_role_binding.sa-rbac
  ]
}

