// Entity → Entity edges a partir de campos JPA (incluye genéricos)
MATCH (e1:Type:Class)-[:ANNOTATED_BY]->(:Annotation)-[:OF_TYPE]->(entTag1:Type)
WHERE entTag1.fqn IN ['javax.persistence.Entity','jakarta.persistence.Entity']

MATCH (e1)-[:DECLARES]->(f:Field)
OPTIONAL MATCH (f)-[:ANNOTATED_BY]->(:Annotation)-[:OF_TYPE]->(relType:Type)
WHERE relType.name IN ['OneToMany','ManyToOne','OneToOne','ManyToMany']

// (A) tipo directo del campo
OPTIONAL MATCH (f)-[:OF_TYPE]->(directT:Type)

// (B) tipo genérico real, si el campo es colección: List<X>, Set<Y>, etc.
OPTIONAL MATCH (f)-[:HAS_ACTUAL_TYPE_ARGUMENT]->(:TypeParameter)-[:OF_RAW_TYPE]->(paramT:Type)

// candidato final: genérico si existe, si no el directo
WITH e1, f, relType,
     coalesce(paramT, directT) AS targetT
WHERE targetT IS NOT NULL

// asegurar que el destino también es @Entity
MATCH (targetT)-[:ANNOTATED_BY]->(:Annotation)-[:OF_TYPE]->(entTag2:Type)
WHERE entTag2.fqn IN ['javax.persistence.Entity','jakarta.persistence.Entity']
WITH e1, targetT, coalesce(relType.name,'Unknown') AS relation
WHERE e1 <> targetT
RETURN e1.fqn AS fromEntity,
       targetT.fqn AS toEntity,
       relation   AS relation
