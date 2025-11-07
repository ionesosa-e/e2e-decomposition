MATCH (f:Field)-[:ANNOTATED_BY]->(a:Annotation)-[:OF_TYPE]->(t:Type)
WHERE t.fqn IN ['org.springframework.beans.factory.annotation.Value', 'jakarta.inject.Inject']
OPTIONAL MATCH (a)-[:HAS]->(:Value {name: 'value'})-[:IS]->(v)
RETURN DISTINCT
f.name AS fieldName,
COALESCE(v.value, 'N/A') AS propertyKey,
f.signature AS fieldType
ORDER BY propertyKey