// Configuration_Environment / Injected_Properties
// Lists injected properties on fields and outputs a cleaned property key.
// Optional scope: when $scopePackage is provided (non-empty),
// limit to declaring classes whose FQN starts with that prefix.

MATCH (dc:Type)-[:DECLARES]->(f:Field)
MATCH (f)-[:ANNOTATED_BY]->(a:Annotation)-[:OF_TYPE]->(t:Type)
WHERE
  t.fqn IN [
    'org.springframework.beans.factory.annotation.Value',
    'jakarta.inject.Inject'
  ]
  AND (
    $scopePackage IS NULL OR trim($scopePackage) = "" OR dc.fqn STARTS WITH $scopePackage
  )

OPTIONAL MATCH (a)-[:HAS]->(:Value {name:'value'})-[:IS]->(v)

WITH
  f,
  coalesce(v.value,'') AS rawKey,
  dc

WITH
  f.name AS fieldName,
  CASE
    WHEN rawKey IS NULL OR trim(rawKey) = '' THEN 'N/A'
    // strip ${...} or #{...} and trailing }
    ELSE apoc.text.replace(apoc.text.replace(apoc.text.replace(rawKey,'${',''),'#{',''),'}','')
  END AS propertyKey,
  f.signature AS fieldType,
  dc.fqn AS declaringClassFqn

RETURN DISTINCT
  fieldName,
  propertyKey,
  fieldType
ORDER BY propertyKey;
