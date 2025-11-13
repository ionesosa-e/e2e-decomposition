// High_Level_Architecture / Excessive_Dependencies
// Finds classes with an excessive number of outgoing dependencies.
// Optional scope: when $scopePackage is provided (non-empty), limit to types whose FQN starts with that prefix.
// If $scopePackage is empty or null, no filtering is applied (full project).

MATCH (t:Type)-[d:DEPENDS_ON]->()
WHERE
  $scopePackage IS NULL OR trim($scopePackage) = "" OR t.fqn STARTS WITH $scopePackage
WITH t, count(d) AS dependencies
WHERE dependencies > 15
RETURN
  t.fqn AS classFqn,
  dependencies
ORDER BY dependencies DESC
