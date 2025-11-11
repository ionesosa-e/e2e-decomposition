// Configuration classes (prefix normalized)
MATCH (c:Type:Class)-[:ANNOTATED_BY]->(a:Annotation)-[:OF_TYPE]->(t:Type)
WHERE t.fqn IN [
  'org.springframework.boot.context.properties.ConfigurationProperties',
  'org.springframework.context.annotation.Configuration'
]
OPTIONAL MATCH (a)-[:HAS]->(:Value {name:'prefix'})-[:IS]->(p)
OPTIONAL MATCH (a)-[:HAS]->(:Value {name:'value'})-[:IS]->(v)
WITH c, t, coalesce(p.value, v.value, '') AS rawPrefix
WITH
  c.fqn AS configClass,
  CASE WHEN rawPrefix IS NULL OR trim(rawPrefix) = '' THEN 'N/A' ELSE rawPrefix END AS propertyPrefix,
  t.name AS annotationType
RETURN configClass, propertyPrefix, annotationType
ORDER BY configClass;
