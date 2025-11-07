MATCH (c:Class)-[:DECLARES]->(m:Method)-[:ANNOTATED_BY]->(ann:Annotation)-[:OF_TYPE]->(at:Type)
WHERE at.fqn IN [
"org.springframework.web.bind.annotation.GetMapping",
"org.springframework.web.bind.annotation.PostMapping",
"org.springframework.web.bind.annotation.PutMapping",
"org.springframework.web.bind.annotation.DeleteMapping",
"org.springframework.web.bind.annotation.RequestMapping"
]

OPTIONAL MATCH (ann)-[:HAS]->(container:Value)-[:CONTAINS]->(pathVal:Value)
WHERE container.name IN ["value", "path"]

OPTIONAL MATCH (c)-[:ANNOTATED_BY]->(ctrlAnn:Annotation)-[:OF_TYPE]->(ctrlType:Type)
WHERE ctrlType.fqn IN [
"org.springframework.web.bind.annotation.RestController",
"org.springframework.stereotype.Controller",
"org.springframework.web.bind.annotation.RequestMapping"
]
OPTIONAL MATCH (ctrlAnn)-[:HAS]->(ctrlContainer:Value)-[:CONTAINS]->(ctrlPathVal:Value)
WHERE ctrlContainer.name IN ["value", "path"]

RETURN
c.fqn AS controller,
m.name AS method,
at.name AS httpMethod,
COALESCE(ctrlPathVal.value, '') + COALESCE(pathVal.value, '') AS completeEndpoint
ORDER BY c.fqn, m.name