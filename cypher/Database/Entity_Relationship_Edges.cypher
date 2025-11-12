// Database / Entity_Relationship_Edges
// Builds Entity→Entity edges from JPA relationship fields (handles generics).
// Optional scope: when $scopePackage is provided (non-empty), limit to source entities whose FQN starts with that prefix.
// If $scopePackage is empty or null, no filtering is applied (full project).

MATCH (e1:Type:Class)-[:ANNOTATED_BY]->(:Annotation)-[:OF_TYPE]->(entTag1:Type)
WHERE entTag1.fqn IN ['javax.persistence.Entity','jakarta.persistence.Entity']
  AND (
    $scopePackage IS NULL OR trim($scopePackage) = "" OR e1.fqn STARTS WITH $scopePackage
  )

MATCH (e1)-[:DECLARES]->(f:Field)
OPTIONAL MATCH (f)-[:ANNOTATED_BY]->(:Annotation)-[:OF_TYPE]->(relType:Type)
WHERE relType.name IN ['OneToMany','ManyToOne','OneToOne','ManyToMany']

// (A) direct field type
OPTIONAL MATCH (f)-[:OF_TYPE]->(directT:Type)

// (B) generic actual type if the field is a collection: List<X>, Set<Y>, etc.
OPTIONAL MATCH (f)-[:HAS_ACTUAL_TYPE_ARGUMENT]->(:TypeParameter)-[:OF_RAW_TYPE]->(paramT:Type)

// Final candidate: prefer generic type when present, otherwise direct type
WITH e1, f, relType, coalesce(paramT, directT) AS targetT
WHERE targetT IS NOT NULL

// Ensure the target is also an @Entity
MATCH (targetT)-[:ANNOTATED_BY]->(:Annotation)-[:OF_TYPE]->(entTag2:Type)
WHERE entTag2.fqn IN ['javax.persistence.Entity','jakarta.persistence.Entity']

WITH e1, targetT, coalesce(relType.name,'Unknown') AS relation
WHERE e1 <> targetT

RETURN
  e1.fqn     AS fromEntity,
  targetT.fqn AS toEntity,
  relation    AS relation
