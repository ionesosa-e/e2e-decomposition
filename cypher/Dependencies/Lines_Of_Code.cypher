// Dependencies / Lines_Of_Code
// Sums effective lines of code per class by aggregating method.effectiveLineCount.
// Optional scope: when $scopePackage is provided (non-empty), limit to types whose FQN starts with that prefix.
// If $scopePackage is empty or null, no filtering is applied (full project).

MATCH (:Artifact)-[:CONTAINS]->(type:Type)-[:DECLARES]->(method:Method)
WHERE
  $scopePackage IS NULL OR trim($scopePackage) = "" OR type.fqn STARTS WITH $scopePackage

RETURN
  type.fqn AS CompleteClassPath,
  sum(coalesce(method.effectiveLineCount, 0)) AS LoC
ORDER BY LoC DESC
