MATCH (t:Type)-[:DECLARES]->(f:Field)-[:HAS_DEFAULT|INITIALIZED_BY]->(l:Literal)
WHERE (l.value CONTAINS 'http://' OR l.value CONTAINS 'https://')
AND l.value =~ 'https?://[^\\s]+'
AND NOT t.fqn =~ '(?i).*\\.test\\..*'
AND NOT t.fqn =~ '(?i).*Test$'
AND NOT t.fqn =~ '(?i).*\\.example\\..*'
AND NOT f.name =~ '(?i).*(doc|example|sample|comment).*'
RETURN DISTINCT l.value AS endpoint, t.fqn as declaringClass, f.name as fieldName
ORDER BY endpoint