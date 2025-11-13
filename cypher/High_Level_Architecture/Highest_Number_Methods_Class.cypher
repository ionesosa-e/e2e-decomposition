// High_Level_Architecture / Highest_Number_Methods_Class
// Lists classes with the highest number of declared methods (threshold > 15).
// Optional scope: when $scopePackage is provided (non-empty), limit to classes whose FQN starts with that prefix.
// If $scopePackage is empty or null, no filtering is applied (full project).

MATCH (class:Class)-[:DECLARES]->(method:Method)
WHERE
  $scopePackage IS NULL OR trim($scopePackage) = "" OR class.fqn STARTS WITH $scopePackage
WITH class, count(method) AS methodCount
WHERE methodCount > 15
RETURN
  class.fqn AS Class,
  methodCount
ORDER BY methodCount DESC
