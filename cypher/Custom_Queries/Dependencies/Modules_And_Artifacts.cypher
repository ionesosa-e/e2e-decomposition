MATCH (a1:Artifact)-[r:DEPENDS_ON]->(a2:Artifact)
RETURN a1.name AS Artifact_1_Name, a1.type AS Artifact_1_Type, a1.version AS Artifact_1_Version, a1.group AS Artifact_1_Group
, a2.name AS Artifact_2_Name, a2.type AS Artifact_2_Type, a2.version AS Artifact_2_Version, a2.group AS Artifact_2_Group