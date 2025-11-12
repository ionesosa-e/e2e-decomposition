// API_Entry_Points / Spring_Controller
// Finds classes annotated with Spring @Controller or @RestController.
// Optional scope: when $scopePackage is provided (non-empty), limit results to controllers whose FQN starts with that prefix.
// If $scopePackage is empty or null, no filtering is applied (full project).

MATCH (c:Class)-[:ANNOTATED_BY]->(a:Annotation)-[:OF_TYPE]->(at:Type)
WHERE
  (at.fqn = "org.springframework.stereotype.Controller"
   OR at.fqn = "org.springframework.web.bind.annotation.RestController")
  AND (
    $scopePackage IS NULL OR trim($scopePackage) = "" OR c.fqn STARTS WITH $scopePackage
  )
RETURN
  c.fqn AS ControllerClassFqn,
  at.fqn AS Package
