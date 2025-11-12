// Dependencies / Modules_And_Artifacts
// Lists Maven artifact→artifact dependency edges.

MATCH (a1:Artifact:Maven)-[:DEPENDS_ON]->(a2:Artifact:Maven)
WHERE
  $scopePackage IS NULL OR trim($scopePackage) = ""
  OR EXISTS {
    MATCH (a1)-[:CONTAINS]->(p:Package)
    WHERE p.fqn STARTS WITH $scopePackage
  }
RETURN DISTINCT
  a1.name    AS Artifact_1_Name,
  a1.type    AS Artifact_1_Type,
  a1.version AS Artifact_1_Version,
  a1.group   AS Artifact_1_Group,
  a2.name    AS Artifact_2_Name,
  a2.type    AS Artifact_2_Type,
  a2.version AS Artifact_2_Version,
  a2.group   AS Artifact_2_Group
ORDER BY
  Artifact_1_Group, Artifact_1_Name,
  Artifact_2_Group, Artifact_2_Name;
