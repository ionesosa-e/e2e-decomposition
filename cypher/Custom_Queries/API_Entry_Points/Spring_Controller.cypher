MATCH (c:Class)-[:ANNOTATED_BY]->(a:Annotation)-[:OF_TYPE]->(at:Type)
WHERE (at.fqn = "org.springframework.stereotype.Controller" OR at.fqn = "org.springframework.web.bind.annotation.RestController")
RETURN c.fqn AS ControllerClassFqn, at.fqn as Package