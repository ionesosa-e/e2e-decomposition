// Database / DB_Schema
// Lists JPA entities, their fields (excluding @Transient), and counts relationship fields.
// Optional scope: when $scopePackage is provided (non-empty), limit to entities whose FQN starts with that prefix.
// If $scopePackage is empty or null, no filtering is applied (full project).

MATCH (e:Type:Class)-[:ANNOTATED_BY]->(:Annotation)-[:OF_TYPE]->(at:Type)
WHERE
  at.fqn IN ['javax.persistence.Entity', 'jakarta.persistence.Entity']
  AND (
    $scopePackage IS NULL OR trim($scopePackage) = "" OR e.fqn STARTS WITH $scopePackage
  )

OPTIONAL MATCH (e)-[:DECLARES]->(f:Field)
WHERE NOT EXISTS {
  MATCH (f)-[:ANNOTATED_BY]->(:Annotation)-[:OF_TYPE]->(transType:Type)
  WHERE transType.fqn CONTAINS 'Transient'
}

OPTIONAL MATCH (f)-[:ANNOTATED_BY]->(:Annotation)-[:OF_TYPE]->(relType:Type)
WHERE relType.fqn IN [
  'javax.persistence.OneToMany',
  'javax.persistence.ManyToOne',
  'javax.persistence.OneToOne',
  'javax.persistence.ManyToMany'
]

RETURN
  e.fqn AS Entity,
  collect(DISTINCT f.name) AS Fields,
  count(DISTINCT CASE WHEN relType IS NOT NULL THEN f END) AS Relationships
ORDER BY Entity
