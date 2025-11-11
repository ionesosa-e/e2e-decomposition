MATCH (:Artifact)-[:CONTAINS]->(type:Type)-[:DECLARES]->(method:Method)
RETURN
type.fqn AS CompleteClassPath, sum(method.effectiveLineCount) AS LoC
ORDER BY LoC DESC