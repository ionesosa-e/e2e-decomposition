// High_Level_Architecture / Cyclomatic_Complexity
// Lists methods whose cyclomatic complexity exceeds a threshold.
// Optional scope: when $scopePackage is provided (non-empty), limit to classes whose FQN starts with that prefix.
// If $scopePackage is empty or null, no filtering is applied (full project).

MATCH (t:Type)-[:DECLARES]->(m:Method)
WHERE
  m.cyclomaticComplexity > 10
  AND (
    $scopePackage IS NULL OR trim($scopePackage) = "" OR t.fqn STARTS WITH $scopePackage
  )
RETURN
  t.fqn AS Class,
  m.name AS Method,
  m.cyclomaticComplexity AS cyclomaticComplexity
ORDER BY cyclomaticComplexity DESC
