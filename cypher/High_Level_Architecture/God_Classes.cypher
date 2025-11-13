// High_Level_Architecture / God_Classes
// Flags classes with a large number of declared methods (heuristic threshold).
// Optional scope: when $scopePackage is provided (non-empty), limit to types whose FQN starts with that prefix.
// If $scopePackage is empty or null, no filtering is applied (full project).

MATCH (t:Type)-[:DECLARES]->(m:Method)
WHERE
  $scopePackage IS NULL OR trim($scopePackage) = "" OR t.fqn STARTS WITH $scopePackage
WITH t, count(m) AS methodCount
WHERE methodCount > 20
RETURN
  t.fqn AS fqn_god_class,
  methodCount
ORDER BY methodCount DESC
