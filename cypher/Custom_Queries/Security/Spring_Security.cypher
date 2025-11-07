MATCH (m:Method)-[:ANNOTATED_BY]->(a:Annotation)-[:OF_TYPE]->(at:Type)
WHERE at.name = 'PreAuthorize'
    OR at.name = 'Secured'
    OR at.name = 'RolesAllowed'
    OR at.name = 'EnableWebSecurity'
RETURN m as Method, a as Annotation