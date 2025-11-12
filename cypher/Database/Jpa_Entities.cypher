// Database / Jpa_Entities
// Lists JPA entities with resolved table names and inheritance flag.
// Optional scope: when $scopePackage is provided (non-empty),
// limit to entities whose FQN starts with that prefix.
// If $scopePackage is empty or null, no filtering is applied (full project).

MATCH (e:Type:Class)
WHERE EXISTS {
  MATCH (e)-[:ANNOTATED_BY]->(:Annotation)-[:OF_TYPE]->(at:Type)
  WHERE at.fqn IN ['javax.persistence.Entity','jakarta.persistence.Entity']
}
AND (
  $scopePackage IS NULL OR trim($scopePackage) = "" OR e.fqn STARTS WITH $scopePackage
)

OPTIONAL MATCH (e)-[:ANNOTATED_BY]->(tableAnn:Annotation)-[:OF_TYPE]->(tableType:Type)
WHERE tableType.fqn IN ['javax.persistence.Table', 'jakarta.persistence.Table']

OPTIONAL MATCH (tableAnn)-[:HAS]->(nameValue:Value {name: 'name'})-[:IS]->(tableName)

OPTIONAL MATCH (e)-[mt:MAPPED_TO|MAPPED_BY]->(t:Table)

RETURN
  e.fqn AS Entity,
  COALESCE(tableName.value, t.name, split(e.fqn, '.')[-1]) AS TableName,
  EXISTS((e)-[:EXTENDS]->()) AS HasInheritance
ORDER BY Entity
