MATCH (a:Artifact)-[:CONTAINS]->(:Package)-[:CONTAINS]->(t:Type)
WITH coalesce(a.fileName, a.name, a.path, a.artifactId, toString(id(a))) AS artifactName,
     count(DISTINCT t) AS numberOfTypes
RETURN artifactName, numberOfTypes
ORDER BY numberOfTypes DESC, artifactName ASC;
