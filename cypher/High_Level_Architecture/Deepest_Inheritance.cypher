MATCH h = (class:Class)-[:EXTENDS*]->(super:Type)
WHERE (NOT EXISTS((super)-[:EXTENDS]->()) AND length(h) > 1)
RETURN class.fqn, length(h) AS Depth
ORDER BY Depth DESC