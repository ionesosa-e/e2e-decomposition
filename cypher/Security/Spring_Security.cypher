// Security / Spring_Security
// Methods annotated with Spring Security annotations (flattened for CSV).
// Optional scope: when $scopePackage is provided (non-empty),
// limit to declaring classes whose FQN starts with that prefix.
// If $scopePackage is empty or null, no filtering is applied (full project).

MATCH (m:Method)-[:ANNOTATED_BY]->(:Annotation)-[:OF_TYPE]->(at:Type)
WHERE at.name IN ['PreAuthorize','Secured','RolesAllowed','EnableWebSecurity']

MATCH (t:Type)-[:DECLARES]->(m)
WHERE
  $scopePackage IS NULL OR trim($scopePackage) = "" OR t.fqn STARTS WITH $scopePackage

RETURN
  t.fqn   AS declaringClass,
  m.name  AS methodName,
  at.name AS annotationName
ORDER BY declaringClass, methodName;
