// Testing / Test_Without_Assertion
// Finds test methods that do not invoke any assertion method.
// Optional scope: when $scopePackage is provided (non-empty),
// limit to tests whose FQN starts with that prefix.
// If $scopePackage is empty or null, no filtering is applied (full project).

MATCH (t:Test:Method)
WHERE
  (
    $scopePackage IS NULL OR trim($scopePackage) = "" OR t.fqn STARTS WITH $scopePackage
  )
  AND NOT (t)-[:INVOKES]->(:Assert:Method)
RETURN
  t AS TestWithoutAssertion
ORDER BY t.fqn
