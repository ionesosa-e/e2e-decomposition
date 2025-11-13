// Fan_In_Fan_Out / Fan_Out
// Computes Fan-Out per type (number of outgoing DEPENDS_ON edges).
// Optional scope: when $scopePackage is provided (non-empty), only consider source types whose FQN starts with that prefix.
// If $scopePackage is empty or null, compute for the whole repository.

MATCH (t:Type)-[:DEPENDS_ON]->(dependent:Type)
WHERE
  ($scopePackage IS NULL OR trim($scopePackage) = "" OR t.fqn STARTS WITH $scopePackage)
  AND NOT t.fqn CONTAINS '$'   // exclude inner classes

WITH t, count(dependent) AS dependents
SET t.fanOut = dependents
RETURN
  t.fqn   AS type,
  t.fanOut AS fanOut
ORDER BY t.fanOut DESC
