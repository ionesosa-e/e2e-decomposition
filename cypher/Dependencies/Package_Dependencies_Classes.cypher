// Dependencies / Package_Dependencies_Classes
// Class-level dependency edges with optional scope on the source class.
// Scope rule: when $scopePackage is provided (non-empty), only include edges where p1.fqn starts with that prefix.
// If $scopePackage is empty or null, no filtering is applied (full project).

MATCH (p1:Class)-[d:DEPENDS_ON]->(p2:Class)
WHERE
  $scopePackage IS NULL OR trim($scopePackage) = "" OR p1.fqn STARTS WITH $scopePackage

RETURN
  p1.fqn AS Class_1_fqn,
  d.weight AS dependencyWeight,
  p2.fqn AS Class_2_fqn
ORDER BY Class_1_fqn, Class_2_fqn
