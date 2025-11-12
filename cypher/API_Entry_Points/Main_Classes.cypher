// API_Entry_Points / Main_Classes
// Finds classes that declare a `main` method.
// Optional scope: when $scopePackage is provided (non-empty), limit results to types whose FQN starts with that prefix.
// If $scopePackage is empty or null, no filtering is applied (full project).

MATCH (t:Type)-[:DECLARES]->(m:Method { name: 'main' })
WHERE
  $scopePackage IS NULL OR trim($scopePackage) = "" OR t.fqn STARTS WITH $scopePackage
RETURN
  t.fqn        AS mainClass,
  m.static     AS isStatic,
  m.visibility AS visibility,
  m.signature  AS signature
