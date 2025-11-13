// External_Integration / Hardcoded_URLs
// Finds hardcoded HTTP/HTTPS URLs in field initializers, excluding tests/examples/docs.
// Optional scope: when $scopePackage is provided (non-empty), limit to declaring classes whose FQN starts with that prefix.
// If $scopePackage is empty or null, no filtering is applied (full project).

MATCH (t:Type)-[:DECLARES]->(f:Field)-[:HAS_DEFAULT|INITIALIZED_BY]->(l:Literal)
WHERE
  (l.value CONTAINS 'http://' OR l.value CONTAINS 'https://')
  AND l.value =~ 'https?://[^\\s]+'
  AND NOT t.fqn =~ '(?i).*\\.test\\..*'
  AND NOT t.fqn =~ '(?i).*Test$'
  AND NOT t.fqn =~ '(?i).*\\.example\\..*'
  AND NOT f.name =~ '(?i).*(doc|example|sample|comment).*'
  AND (
    $scopePackage IS NULL OR trim($scopePackage) = "" OR t.fqn STARTS WITH $scopePackage
  )
RETURN DISTINCT
  l.value AS endpoint,
  t.fqn   AS declaringClass,
  f.name  AS fieldName
ORDER BY endpoint
