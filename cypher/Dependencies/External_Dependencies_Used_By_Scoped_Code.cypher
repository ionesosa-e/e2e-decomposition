// Dependencies / External_Dependencies_Used_By_Scoped_Code
// Lists external artifacts that are actually referenced by code.
// Definition: types in artifact A1 that depend on types in artifact A2 (A1 != A2).
// Optional scope: when $scopePackage is provided (non-empty), only consider source packages starting with that prefix.
// If $scopePackage is empty or null, consider the whole repository.

MATCH (a1:Artifact)-[:CONTAINS]->(p1:Package)-[:CONTAINS]->(t1:Type)
WHERE
  $scopePackage IS NULL OR trim($scopePackage) = "" OR p1.fqn STARTS WITH $scopePackage

MATCH (t1)-[:DEPENDS_ON]->(t2:Type)<-[:CONTAINS]-(p2:Package)<-[:CONTAINS]-(a2:Artifact)
WHERE a1 <> a2

RETURN DISTINCT
  a2.group   AS group,
  a2.name    AS name,
  a2.version AS version
ORDER BY group, name
