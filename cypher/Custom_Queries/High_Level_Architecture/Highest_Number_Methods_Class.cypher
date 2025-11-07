MATCH (class:Class)-[:DECLARES]->(method:Method)
WITH class, count(method) as methodCount
WHERE methodCount > 15
RETURN class.fqn, methodCount
ORDER BY methodCount DESC