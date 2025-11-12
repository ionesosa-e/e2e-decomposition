// Dependencies / Circular_Dependencies
// Finds circular dependencies between packages with sample edges in both directions.
// Optional scope: when $scopePackage is provided (non-empty), both packages must start with that prefix.
// If $scopePackage is empty or null, no package filter is applied (full project).

MATCH (p1:Package)-[:CONTAINS]->(t1:Type)-[:DEPENDS_ON]->(t2:Type)<-[:CONTAINS]-(p2:Package)
WHERE
  (
    $scopePackage IS NULL OR trim($scopePackage) = ""
    OR (p1.fqn STARTS WITH $scopePackage AND p2.fqn STARTS WITH $scopePackage)
  )
  AND p1.fqn < p2.fqn
  AND NOT t1.fqn CONTAINS '$'
  AND NOT t2.fqn CONTAINS '$'

WITH p1, p2, count(*) AS forwardCount
WHERE forwardCount > 0
  AND EXISTS {
    MATCH (p2)-[:CONTAINS]->(:Type)-[:DEPENDS_ON]->(:Type)<-[:CONTAINS]-(p1)
  }

MATCH (p1)-[:CONTAINS]->(t1:Type)-[:DEPENDS_ON]->(t2:Type)<-[:CONTAINS]-(p2)
WHERE NOT t1.fqn CONTAINS '$' AND NOT t2.fqn CONTAINS '$'
WITH p1, p2, forwardCount,
     collect(t1.name + ' → ' + t2.name)[0..5] AS forwardExamples

MATCH (p2)-[:CONTAINS]->(t3:Type)-[:DEPENDS_ON]->(t4:Type)<-[:CONTAINS]-(p1)
WHERE NOT t3.fqn CONTAINS '$' AND NOT t4.fqn CONTAINS '$'
WITH p1, p2, forwardCount, forwardExamples,
     count(*) AS backwardCount,
     collect(t3.name + ' → ' + t4.name)[0..5] AS backwardExamples

OPTIONAL MATCH (a1:Artifact)-[:CONTAINS]->(p1)
OPTIONAL MATCH (a2:Artifact)-[:CONTAINS]->(p2)

RETURN
  a1.name AS artifact1,
  p1.fqn  AS package1,
  a2.name AS artifact2,
  p2.fqn  AS package2,
  forwardCount          AS totalDepsP1toP2,
  backwardCount         AS totalDepsP2toP1,
  forwardExamples       AS sampleDepsP1toP2,
  backwardExamples      AS sampleDepsP2toP1
ORDER BY (forwardCount + backwardCount) DESC
LIMIT 50
