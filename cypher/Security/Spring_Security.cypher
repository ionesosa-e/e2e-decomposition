// Methods annotated with Spring Security annotations (flattened for CSV)
MATCH (m:Method)-[:ANNOTATED_BY]->(:Annotation)-[:OF_TYPE]->(at:Type)
WHERE at.name IN ['PreAuthorize','Secured','RolesAllowed','EnableWebSecurity']
MATCH (t:Type)-[:DECLARES]->(m)
RETURN
  t.fqn      AS declaringClass,
  m.name     AS methodName,
  at.name    AS annotationName
ORDER BY declaringClass, methodName;
