MATCH (e:Type:Class)-[:DECLARES]->(f:Field)
WHERE EXISTS {
    MATCH (e)-[:ANNOTATED_BY]->(:Annotation)-[:OF_TYPE]->(at:Type)
    WHERE at.fqn IN ['javax.persistence.Entity', 'jakarta.persistence.Entity']
}
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
RETURN e.fqn as Entity,
        f.name as Field,
        f.signature as Type,
        COLLECT(DISTINCT annType.name) as Annotations,
        COLLECT(DISTINCT colValue.value) as ColumnNames
ORDER BY Entity, Field