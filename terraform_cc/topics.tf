# Create Topics
resource "confluent_kafka_topic" "irops_events" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  topic_name       = "irops_events"
  partitions_count = 1
  rest_endpoint    = confluent_kafka_cluster.cluster.rest_endpoint

  credentials {
    key    = confluent_api_key.apikey.id
    secret = confluent_api_key.apikey.secret
  }
}

resource "confluent_kafka_topic" "flight_manifest" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  topic_name       = "flight_manifest"
  partitions_count = 1
  rest_endpoint    = confluent_kafka_cluster.cluster.rest_endpoint

  credentials {
    key    = confluent_api_key.apikey.id
    secret = confluent_api_key.apikey.secret
  }
}

resource "confluent_kafka_topic" "hotel_inventory" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  topic_name       = "hotel_inventory"
  partitions_count = 1
  rest_endpoint    = confluent_kafka_cluster.cluster.rest_endpoint

  credentials {
    key    = confluent_api_key.apikey.id
    secret = confluent_api_key.apikey.secret
  }
}

resource "confluent_kafka_topic" "transport_availability" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  topic_name       = "transport_availability"
  partitions_count = 1
  rest_endpoint    = confluent_kafka_cluster.cluster.rest_endpoint

  credentials {
    key    = confluent_api_key.apikey.id
    secret = confluent_api_key.apikey.secret
  }
}

resource "confluent_kafka_topic" "flight_schedule" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  topic_name       = "flight_schedule"
  partitions_count = 1
  rest_endpoint    = confluent_kafka_cluster.cluster.rest_endpoint

  credentials {
    key    = confluent_api_key.apikey.id
    secret = confluent_api_key.apikey.secret
  }
}