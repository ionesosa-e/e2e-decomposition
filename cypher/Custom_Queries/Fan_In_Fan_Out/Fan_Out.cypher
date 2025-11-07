// TODO: Reemplaza 'com.salesmanager' con el paquete raíz de tu proyecto
WITH 'com.salesmanager' AS PROJECT_PACKAGE_PREFIX

MATCH (t:Type)-[:DEPENDS_ON]->(dependent:Type)
WHERE t.fqn STARTS WITH PROJECT_PACKAGE_PREFIX
AND NOT t.fqn CONTAINS '$'  // Excluir inner classes
WITH t, count(dependent) AS dependents
SET t.fanOut = dependents
RETURN t.fqn AS type, t.fanOut AS fanOut
ORDER BY t.fanOut DESC