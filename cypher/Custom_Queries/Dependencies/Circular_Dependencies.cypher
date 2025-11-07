MATCH (p1:Package)-[:CONTAINS]->(t1:Type)-[:DEPENDS_ON]->(t2:Type)<-[:CONTAINS]-(p2:Package)
WHERE p1 <> p2
AND NOT t1.fqn CONTAINS '$'
AND NOT t2.fqn CONTAINS '$'

MATCH (p2)-[:CONTAINS]->(t3:Type)-[:DEPENDS_ON]->(t4:Type)<-[:CONTAINS]-(p1)
WHERE NOT t3.fqn CONTAINS '$'
AND NOT t4.fqn CONTAINS '$'

AND p1.fqn < p2.fqn

WITH p1, p2,
        COLLECT(DISTINCT t1.fqn) AS classesP1toP2,
        COLLECT(DISTINCT t3.fqn) AS classesP2toP1

RETURN DISTINCT
    p1.fqn AS Package1,
    p2.fqn AS Package2,
    SIZE(classesP1toP2) AS DependenciesP1toP2,
    SIZE(classesP2toP1) AS DependenciesP2toP1,
    classesP1toP2 AS ClassesFromP1ToP2,
    classesP2toP1 AS ClassesFromP2ToP1,
    'WARNING: Cyclic package dependency' AS Violation
ORDER BY (SIZE(classesP1toP2) + SIZE(classesP2toP1)) DESC