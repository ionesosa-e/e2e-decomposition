MATCH (c:Type:Class)-[:ANNOTATED_BY]->(a:Annotation)-[:OF_TYPE]->(t:Type)
WHERE t.fqn IN [
    'org.springframework.boot.context.properties.ConfigurationProperties',
    'org.springframework.context.annotation.Configuration'
]
OPTIONAL MATCH (a)-[:HAS]->(:Value {name: 'prefix'})-[:IS]->(prefix)
OPTIONAL MATCH (a)-[:HAS]->(:Value {name: 'value'})-[:IS]->(value)
RETURN c.fqn AS configClass,
        COALESCE(prefix.value, value.value, 'N/A') AS propertyPrefix,
        t.name AS annotationType
ORDER BY configClass