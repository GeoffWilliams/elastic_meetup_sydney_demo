-- Extract passengers with connections from DIVERTING events for SMS notifications
-- One notification per passenger with a connection

CREATE TABLE sms_notification (
    event_id STRING,
    pnr STRING,
    flight_number STRING,
    passenger_name STRING,
    onward_connection STRING,
    notification_type STRING,
    message STRING,
    PRIMARY KEY (event_id, pnr) NOT ENFORCED
) WITH (
    'value.format' = 'json-registry'
);

-- Insert SMS notifications for passengers with connections on DIVERTING flights
INSERT INTO sms_notification
SELECT
    e.event_id,
    cp.pnr,
    e.flight_number,
    cp.name AS passenger_name,
    cp.onward_connection,
    'CONNECTION_AT_RISK' AS notification_type,
    CONCAT(
        'URGENT: Flight ', e.flight_number,
        ' is diverting. Your connection to ', cp.onward_connection,
        ' may be affected. Please contact airline staff upon landing.'
    ) AS message
FROM enriched_irops_events e
CROSS JOIN UNNEST(e.connection_passengers) AS cp(pnr, name, onward_connection)
WHERE e.status = 'DIVERTING';

-- Made with Bob