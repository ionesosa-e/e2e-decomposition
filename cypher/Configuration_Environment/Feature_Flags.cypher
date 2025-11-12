// Configuration_Environment / Feature_Flags
// Detects potential feature flags: boolean fields with suggestive names.
// Optional scope: when $scopePackage is provided (non-empty),
// limit to declaring classes whose FQN starts with that prefix.

MATCH (declaringClass:Type)-[:DECLARES]->(f:Field)
WHERE
  f.name =~ '(?i).*(feature|flag|toggle|enable|disable).*'
  AND f.signature CONTAINS 'boolean'
  AND (
    $scopePackage IS NULL OR trim($scopePackage) = "" OR declaringClass.fqn STARTS WITH $scopePackage
  )

OPTIONAL MATCH (f)-[:ANNOTATED_BY]->(a:Annotation)-[:OF_TYPE]->(t:Type)
WHERE t.fqn = 'org.springframework.beans.factory.annotation.Value'

OPTIONAL MATCH (a)-[:HAS]->(:Value {name: 'value'})-[:IS]->(v)

RETURN DISTINCT
  f.name AS fieldName,
  declaringClass.fqn AS declaringClass,
  COALESCE(v.value, 'Hardcoded') AS source
ORDER BY fieldName
