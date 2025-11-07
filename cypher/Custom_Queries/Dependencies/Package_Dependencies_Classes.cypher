MATCH (p1:Class)-[d:DEPENDS_ON]->(p2:Class)
RETURN p1.fqn as Class_1_fqn, d.weight as dependencyWeight, p2.fqn as Class_2_fqn