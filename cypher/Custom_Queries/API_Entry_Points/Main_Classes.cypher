MATCH (t:Type)-[:DECLARES]->(m:Method { name: 'main' })
RETURN t.fqn AS mainClass, m.static AS isStatic, m.visibility AS visibility, m.signature AS signature