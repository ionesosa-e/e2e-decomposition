MATCH (a:Artifact)-[:CONTAINS]->(p:Package)
WITH coalesce(a.fileName, a.name, a.path, a.artifactId, toString(id(a))) AS artifactName,
     count(DISTINCT p) AS numberOfPackages
RETURN artifactName, numberOfPackages
ORDER BY numberOfPackages DESC, artifactName ASC;
