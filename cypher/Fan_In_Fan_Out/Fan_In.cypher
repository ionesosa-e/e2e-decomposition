WITH 'com.salesmanager' AS PROJECT_PACKAGE_PREFIX
MATCH (t:Type)<-[:DEPENDS_ON]-(dependent:Type)
WHERE t.fqn STARTS WITH PROJECT_PACKAGE_PREFIX
AND NOT t.fqn CONTAINS '$'  // Excluir inner classes
WITH t, count(dependent) AS dependents
SET t.fanIn = dependents
RETURN t.fqn AS type, t.fanIn AS fanIn
ORDER BY t.fanIn DESC