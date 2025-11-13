// High_Level_Architecture / Package_Structure
// Lists package FQNs for building a package structure overview.
// Optional scope: when $scopePackage is provided (non-empty), limit to packages whose FQN starts with that prefix.
// If $scopePackage is empty or null, no filtering is applied (full project).

MATCH (p:Package)
WHERE
  $scopePackage IS NULL
  OR trim($scopePackage) = ""
  OR p.fqn STARTS WITH $scopePackage
RETURN
  p.fqn AS packageFqn
ORDER BY packageFqn
