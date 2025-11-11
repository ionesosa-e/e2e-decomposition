MATCH (f:Field)
WHERE f.name =~ '(?i).*(feature|flag|toggle|enable|disable).*'
AND f.signature CONTAINS 'boolean'
OPTIONAL MATCH (f)-[:ANNOTATED_BY]->(a:Annotation)-[:OF_TYPE]->(t:Type)
WHERE t.fqn = 'org.springframework.beans.factory.annotation.Value'
OPTIONAL MATCH (a)-[:HAS]->(:Value {name: 'value'})-[:IS]->(v)
OPTIONAL MATCH (f)<-[:DECLARES]-(declaringClass:Type)
RETURN DISTINCT
    f.name AS fieldName,
    declaringClass.fqn AS declaringClass,
    COALESCE(v.value, 'Hardcoded') AS source
ORDER BY fieldName