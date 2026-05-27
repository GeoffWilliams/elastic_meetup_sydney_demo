-- Compare Scheduled vs Actual Flight Operations
CREATE TABLE flight_performance_summary (
    flight_number STRING,
    scheduled_destination STRING,
    scheduled_arrival_time STRING,
    actual_landing_airport STRING,
    actual_landing_time STRING,
    arrival_delay_minutes INT,
    arrival_status STRING,
    PRIMARY KEY (flight_number) NOT ENFORCED
)
WITH (
    'value.format' = 'json-registry'
);

-- Insert the comparison data
INSERT INTO flight_performance_summary
SELECT
    fs.flight_number,
    fs.destination AS scheduled_destination,
    fs.scheduled_arrival AS scheduled_arrival_time,
    -- Get the most recent location (current_location if set, otherwise diversion_airport)
    MAX(COALESCE(ie.current_location, ie.diversion_airport)) AS actual_landing_airport,
    -- Get the most recent timestamp
    MAX(ie.`timestamp`) AS actual_landing_time,
    TIMESTAMPDIFF(
        MINUTE,
        TO_TIMESTAMP(fs.scheduled_arrival, 'yyyy-MM-dd''T''HH:mm:ss''Z'''),
        TO_TIMESTAMP(MAX(ie.`timestamp`), 'yyyy-MM-dd''T''HH:mm:ss''Z''')
    ) AS arrival_delay_minutes,
    -- Did it land at the right airport?
    CASE
        WHEN MAX(COALESCE(ie.current_location, ie.diversion_airport)) = fs.destination
        THEN 'ARRIVED_AT_SCHEDULED_DESTINATION'
        ELSE 'DIVERTED_TO_ALTERNATE'
    END AS arrival_status
FROM flight_schedule fs
LEFT JOIN irops_events ie
    ON fs.flight_number = ie.flight_number
GROUP BY fs.flight_number, fs.destination, fs.scheduled_arrival;

-- Made with Bob
