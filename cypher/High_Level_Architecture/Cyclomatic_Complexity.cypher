MATCH (t:Type)-[:DECLARES]->(m:Method)
WHERE m.cyclomaticComplexity > 10
RETURN t.fqn as Class, m.name as Method, m.cyclomaticComplexity as cyclomaticComplexity
ORDER BY cyclomaticComplexity DESC