// High_Level_Architecture / Inheritance_Between_Classes
// Lists class inheritance edges (c1 EXTENDS c2), excluding java.lang.Object.
// Optional scope: when $scopePackage is provided (non-empty), limit to child classes whose FQN starts with that prefix.
// If $scopePackage is empty or null, no filtering is applied (full project).

MATCH (c1:Class)-[:EXTENDS]->(c2:Type)
WHERE
  c2.fqn <> "java.lang.Object"
  AND (
    $scopePackage IS NULL OR trim($scopePackage) = "" OR c1.fqn STARTS WITH $scopePackage
  )
RETURN
  c1.fqn AS class_1_fqn,
  'Inherits' AS relation,
  c2.fqn AS class_2_fqn
ORDER BY class_1_fqn, class_2_fqn
