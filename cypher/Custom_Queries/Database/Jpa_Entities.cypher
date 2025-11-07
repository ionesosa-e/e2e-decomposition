MATCH (e:Type:Class)
WHERE EXISTS {
    MATCH (e)-[:ANNOTATED_BY]->(:Annotation)-[:OF_TYPE]->(at:Type)
    WHERE at.fqn IN [
        'javax.persistence.Entity',
        'jakarta.persistence.Entity'
    ]
}
OPTIONAL MATCH (e)-[:ANNOTATED_BY]->(tableAnn:Annotation)-[:OF_TYPE]->(tableType:Type)
WHERE tableType.fqn IN ['javax.persistence.Table', 'jakarta.persistence.Table']
OPTIONAL MATCH (tableAnn)-[:HAS]->(nameValue:Value {name: 'name'})-[:IS]->(tableName)
OPTIONAL MATCH (e)-[mt:MAPPED_TO|MAPPED_BY]->(t:Table)
RETURN e.fqn as Entity,
        COALESCE(tableName.value, t.name, split(e.fqn, '.')[-1]) as TableName,
        EXISTS((e)-[:EXTENDS]->()) as HasInheritance
ORDER BY Entity