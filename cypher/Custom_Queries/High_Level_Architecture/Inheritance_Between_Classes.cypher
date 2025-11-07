MATCH (c1:Class)-[:EXTENDS]->(c2:Type) WHERE NOT (c2.fqn = "java.lang.Object")
RETURN c1.fqn as class_1_fqn, 'Inherits'  ,c2.fqn as class_2_fqn