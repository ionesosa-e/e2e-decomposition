MATCH (t:Type)-[:DECLARES]->(m:Method)
WITH t, count(m) as methodCount
WHERE methodCount > 20
RETURN t.fqn as fqn_god_class, methodCount
ORDER BY methodCount DESC