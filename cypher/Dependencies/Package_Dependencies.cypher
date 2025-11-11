MATCH (p1:Package)-[:CONTAINS]->(t1:Type)-[:DEPENDS_ON]->(t2:Type)<-[:CONTAINS]-(p2:Package)
WHERE p1 <> p2
RETURN
    p1.fqn AS originPackage,
    p2.fqn AS destinationPackage,
    count(DISTINCT t1) AS typesThatDepend,
    count(*) AS totalDependencies
ORDER BY totalDependencies DESC