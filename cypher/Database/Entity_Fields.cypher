// Database / Entity_Fields
// Lists fields of JPA entities and their relevant annotations (including column names when present).
// Optional scope: when $scopePackage is provided (non-empty), limit to entities whose FQN starts with that prefix.
// If $scopePackage is empty or null, no filtering is applied (full project).

MATCH (e:Type:Class)-[:DECLARES]->(f:Field)
WHERE EXISTS {
  MATCH (e)-[:ANNOTATED_BY]->(:Annotation)-[:OF_TYPE]->(at:Type)
  WHERE at.fqn IN ['javax.persistence.Entity', 'jakarta.persistence.Entity']
}
AND (
  $scopePackage IS NULL OR trim($scopePackage) = "" OR e.fqn STARTS WITH $scopePackage
)

OPTIONAL MATCH (f)-[:ANNOTATED_BY]->(ann:Annotation)-[:OF_TYPE]->(annType:Type)
WHERE annType.fqn IN [
  'javax.persistence.Column', 'jakarta.persistence.Column',
  'javax.persistence.Id', 'jakarta.persistence.Id',
  'javax.persistence.GeneratedValue', 'jakarta.persistence.GeneratedValue',
  'javax.persistence.OneToMany', 'jakarta.persistence.OneToMany',
  'javax.persistence.ManyToOne', 'jakarta.persistence.ManyToOne',
  'javax.persistence.ManyToMany', 'jakarta.persistence.ManyToMany',
  'javax.persistence.OneToOne', 'jakarta.persistence.OneToOne',
  'javax.persistence.JoinColumn', 'jakarta.persistence.JoinColumn',
  'javax.persistence.Transient', 'jakarta.persistence.Transient'
]

OPTIONAL MATCH (ann)-[:HAS]->(colName:Value {name: 'name'})-[:IS]->(colValue)

RETURN
  e.fqn AS Entity,
  f.name AS Field,
  f.signature AS Type,
  COLLECT(DISTINCT annType.name) AS Annotations,
  COLLECT(DISTINCT colValue.value) AS ColumnNames
ORDER BY Entity, Field
