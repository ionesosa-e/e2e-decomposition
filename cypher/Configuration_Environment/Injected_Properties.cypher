// Injected properties with cleaned keys (supports ${...} and #{...})
MATCH (f:Field)-[:ANNOTATED_BY]->(a:Annotation)-[:OF_TYPE]->(t:Type)
WHERE t.fqn IN [
  'org.springframework.beans.factory.annotation.Value',
  'jakarta.inject.Inject'
]
OPTIONAL MATCH (a)-[:HAS]->(:Value {name:'value'})-[:IS]->(v)
WITH
  f,
  coalesce(v.value,'') AS rawKey
WITH
  f.name AS fieldName,
  CASE
    WHEN rawKey IS NULL OR trim(rawKey) = '' THEN 'N/A'
    // strip ${...} or #{...} and trailing }
    ELSE apoc.text.replace(apoc.text.replace(apoc.text.replace(rawKey,'${',''),'#{',''),'}','')
  END AS propertyKey,
  f.signature AS fieldType
RETURN DISTINCT fieldName, propertyKey, fieldType
ORDER BY propertyKey;
