MATCH (t:Type)-[:DEPENDS_ON]->(dependent:Type)
WHERE t.fqn STARTS WITH $projectPackagePrefix
AND NOT t.fqn CONTAINS '$'  // Excluir inner classes
WITH t, count(dependent) AS dependents
SET t.fanOut = dependents
RETURN t.fqn AS type, t.fanOut AS fanOut
ORDER BY t.fanOut DESC