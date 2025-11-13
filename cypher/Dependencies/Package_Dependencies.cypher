// Dependencies / Package_Dependencies
// Aggregates type-level dependencies into package→package edges with counts.
// Optional scope: when $scopePackage is provided (non-empty), only include origins whose package FQN starts with that prefix.
// If $scopePackage is empty or null, no filtering is applied (full project).

MATCH (p1:Package)-[:CONTAINS]->(t1:Type)-[:DEPENDS_ON]->(t2:Type)<-[:CONTAINS]-(p2:Package)
WHERE
  p1 <> p2
  AND (
    $scopePackage IS NULL OR trim($scopePackage) = "" OR p1.fqn STARTS WITH $scopePackage
  )
RETURN
  p1.fqn AS originPackage,
  p2.fqn AS destinationPackage,
  count(DISTINCT t1) AS typesThatDepend,
  count(*) AS totalDependencies
ORDER BY totalDependencies DESC
