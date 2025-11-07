MATCH (e:Type:Class)-[:ANNOTATED_BY]->(:Annotation)-[:OF_TYPE]->(at:Type)
WHERE at.fqn IN ['javax.persistence.Entity', 'jakarta.persistence.Entity']

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