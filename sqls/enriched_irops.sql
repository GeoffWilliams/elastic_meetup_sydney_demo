-- Final Enrichment Job: Join IROPS events with passenger data
-- This version actually works and populates the passenger arrays!
CREATE TABLE enriched_irops_events
WITH (
    'value.format' = 'json-registry'
)
AS SELECT 
    e.event_id,
    e.event_type,
    TO_TIMESTAMP(e.`timestamp`, 'yyyy-MM-dd''T''HH:mm:ss''Z''') AS `timestamp`,
    e.flight_number,
    e.status,
    e.origin,
    e.destination,
    CAST(COALESCE(e.delay_minutes, 0) AS INT) AS delay_minutes,
    e.reason,
    pax.vulnerable_passengers,
    pax.connection_passengers,
    CAST(COALESCE(pax.total_passengers, 0) AS INT) AS total_passengers,
    CAST(COALESCE(pax.vulnerable_count, 0) AS INT) AS vulnerable_count,
    CAST(COALESCE(pax.connection_count, 0) AS INT) AS connection_count
FROM irops_events e
LEFT JOIN (
    SELECT 
        m.flight,
        COLLECT(
            CASE 
                WHEN CARDINALITY(p.ssr_codes) > 0 
                THEN ROW(p.pnr, p.name, p.ssr_codes)
                ELSE NULL
            END
        ) FILTER (WHERE CARDINALITY(p.ssr_codes) > 0) AS vulnerable_passengers,
        COLLECT(
            CASE 
                WHEN p.onward_connection IS NOT NULL 
                THEN ROW(p.pnr, p.name, p.onward_connection)
                ELSE NULL
            END
        ) FILTER (WHERE p.onward_connection IS NOT NULL) AS connection_passengers,
        CARDINALITY(m.passengers) AS total_passengers,
        COUNT(CASE WHEN CARDINALITY(p.ssr_codes) > 0 THEN 1 END) AS vulnerable_count,
        COUNT(CASE WHEN p.onward_connection IS NOT NULL THEN 1 END) AS connection_count
    FROM flight_manifest m
    CROSS JOIN UNNEST(m.passengers) AS p
    GROUP BY m.flight, m.passengers
) pax ON e.flight_number = pax.flight;

-- Made with Bob
