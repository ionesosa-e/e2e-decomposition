MATCH (t:Type)-[:DECLARES]->(m:Method { name: 'main' })
RETURN t AS mainClass, m AS entryPoint