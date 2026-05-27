#!/usr/bin/env python3
"""
Script to send test data to Confluent Cloud Kafka topics.
Reads connection details from .env file and sends JSON test data to appropriate topics.

Usage:
    python send_test_data.py                    # Send all data
    python send_test_data.py --schedules        # Send only flight schedules
    python send_test_data.py --reference        # Send only reference data
    python send_test_data.py --irops            # Send only IROPS events
    python send_test_data.py --schedules --irops # Send schedules and IROPS
"""

import argparse
import json
import os
from pathlib import Path
from confluent_kafka import Producer
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Get Kafka configuration from environment
BOOTSTRAP_SERVERS = os.getenv('CONNECT_BOOTSTRAP_SERVERS', '').replace('SASL_SSL://', '')
API_KEY = os.getenv('CC_API_KEY')
API_SECRET = os.getenv('CC_API_KEY_SECRET')

# Kafka producer configuration
config = {
    'bootstrap.servers': BOOTSTRAP_SERVERS,
    'security.protocol': 'SASL_SSL',
    'sasl.mechanisms': 'PLAIN',
    'sasl.username': API_KEY,
    'sasl.password': API_SECRET,
}

def delivery_report(err, msg):
    """Callback for message delivery reports."""
    if err is not None:
        print(f'❌ Message delivery failed: {err}')
    else:
        print(f'✅ Message delivered to {msg.topic()} [partition {msg.partition()}]')

def send_flight_schedules(producer, topic, json_file_path):
    """Send individual flight schedules from a schedules array."""
    try:
        with open(json_file_path, 'r') as f:
            data = json.load(f)
        
        # Extract schedules array
        schedules = data.get('schedules', [])
        
        for schedule in schedules:
            flight_number = schedule.get('flight_number', 'UNKNOWN')
            message = json.dumps(schedule)
            
            # Send to Kafka with flight number as key
            producer.produce(
                topic=topic,
                key=flight_number,
                value=message,
                callback=delivery_report
            )
            producer.poll(0)
        
        # Wait for all messages to be delivered
        producer.flush()
        
        print(f'📤 Sent {len(schedules)} flight schedules to {topic}')
        
    except Exception as e:
        print(f'❌ Error sending flight schedules: {e}')

def send_json_to_topic(producer, topic, json_file_path, key=None):
    """Send JSON file content to a Kafka topic."""
    try:
        with open(json_file_path, 'r') as f:
            data = json.load(f)
        
        # Convert to JSON string
        message = json.dumps(data)
        
        # Send to Kafka
        producer.produce(
            topic=topic,
            key=key,
            value=message,
            callback=delivery_report
        )
        
        # Wait for message to be delivered
        producer.flush()
        
        print(f'📤 Sent {json_file_path} to topic: {topic}')
        
    except Exception as e:
        print(f'❌ Error sending {json_file_path}: {e}')

def main():
    """Main function to send test data to Kafka topics."""
    # Parse command line arguments
    parser = argparse.ArgumentParser(
        description='Send test data to Confluent Cloud Kafka topics',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python send_test_data.py                    # Send all data
  python send_test_data.py --schedules        # Send only flight schedules
  python send_test_data.py --reference        # Send only reference data
  python send_test_data.py --irops            # Send only IROPS events
  python send_test_data.py --schedules --irops # Send schedules and IROPS
        """
    )
    parser.add_argument('--schedules', action='store_true',
                       help='Send flight schedules')
    parser.add_argument('--reference', action='store_true',
                       help='Send reference data (manifest, hotel, transport)')
    parser.add_argument('--irops', action='store_true',
                       help='Send IROPS events')
    parser.add_argument('--all', action='store_true',
                       help='Send all data (default if no options specified)')
    
    args = parser.parse_args()
    
    # If no specific options, send all
    send_all = args.all or not (args.schedules or args.reference or args.irops)
    
    print('🚀 Starting Confluent Cloud data upload...\n')
    print(f'📡 Connecting to: {BOOTSTRAP_SERVERS}\n')
    
    # Create Kafka producer
    producer = Producer(config)
    
    # Send flight schedules
    if send_all or args.schedules:
        print('📋 Sending flight schedules...')
        flight_schedule_path = '../test_data/flight_schedule.json'
        if Path(flight_schedule_path).exists():
            send_flight_schedules(producer, 'flight_schedule', flight_schedule_path)
        else:
            print(f'⚠️  File not found: {flight_schedule_path}')
    
    # Send reference data
    if send_all or args.reference:
        # Define mappings of files to topics
        single_files = [
            ('../test_data/flight_manifest.json', 'flight_manifest', 'TB519'),
            ('../test_data/hotel_inventory.json', 'hotel_inventory', 'OOL'),
            ('../test_data/transport_availability.json', 'transport_availability', 'OOL-BNE'),
        ]
        
        print('\n📋 Sending reference data...')
        for file_path, topic, key in single_files:
            if Path(file_path).exists():
                send_json_to_topic(producer, topic, file_path, key)
            else:
                print(f'⚠️  File not found: {file_path}')
    
    # Send IROPS events
    if send_all or args.irops:
        print('\n📋 Sending IROPS events...')
        irops_dir = Path('../test_data/irops_events')
        if irops_dir.exists():
            irops_files = sorted(irops_dir.glob('*.json'))
            for irops_file in irops_files:
                # Use event filename as key for ordering
                key = irops_file.stem
                send_json_to_topic(producer, 'irops_events', str(irops_file), key)
        else:
            print(f'⚠️  Directory not found: {irops_dir}')
    
    print('\n✨ Data sent successfully!')
    print('🔍 You can now view the messages in Confluent Cloud Console')

if __name__ == '__main__':
    main()

# Made with Bob
