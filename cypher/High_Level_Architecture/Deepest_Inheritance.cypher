// High_Level_Architecture / Deepest_Inheritance
// Finds inheritance chains ending at a root type (no further EXTENDS)
// and returns the deepest class hierarchies.
// Optional scope: when $scopePackage is provided (non-empty),
// limit to classes whose FQN starts with that prefix.
// If $scopePackage is empty or null, no filtering is applied (full project).

MATCH h = (class:Class)-[:EXTENDS*]->(super:Type)
WHERE
  NOT EXISTS ( (super)-[:EXTENDS]->() )
  AND length(h) > 1
  AND (
    $scopePackage IS NULL OR trim($scopePackage) = "" OR class.fqn STARTS WITH $scopePackage
  )
RETURN
  class.fqn AS Class,
  length(h) AS Depth
ORDER BY Depth DESC
