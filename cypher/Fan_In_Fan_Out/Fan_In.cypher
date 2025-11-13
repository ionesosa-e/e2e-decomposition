// Fan_In_Fan_Out / Fan_In
// Computes Fan-In per type (number of incoming DEPENDS_ON edges).
// Optional scope: when $scopePackage is provided (non-empty), only consider target types whose FQN starts with that prefix.
// If $scopePackage is empty or null, compute for the whole repository.

MATCH (t:Type)<-[:DEPENDS_ON]-(dependent:Type)
WHERE
  ($scopePackage IS NULL OR trim($scopePackage) = "" OR t.fqn STARTS WITH $scopePackage)
  AND NOT t.fqn CONTAINS '$'   // exclude inner classes

WITH t, count(dependent) AS dependents
SET t.fanIn = dependents
RETURN
  t.fqn  AS type,
  t.fanIn AS fanIn
ORDER BY t.fanIn DESC
