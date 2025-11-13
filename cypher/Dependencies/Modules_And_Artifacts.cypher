// Dependencies / Modules_And_Artifacts
// Lists artifact→artifact dependency edges.
// Optional scope: when $scopePackage is provided (non-empty),
// only include edges where the source artifact (a1) contains packages under that prefix.
// If $scopePackage is empty or null, all artifact edges are returned (global).

MATCH (a1:Artifact)-[:DEPENDS_ON]->(a2:Artifact)
WHERE
  // Scope: si no hay scopePackage → no filtra
  (
    $scopePackage IS NULL OR trim($scopePackage) = ""
    OR EXISTS {
      MATCH (a1)-[:CONTAINS]->(p:Package)
      WHERE p.fqn STARTS WITH $scopePackage
    }
  )
  // Robustez extra: solo artefactos que tengan algún identificador razonable
  AND coalesce(a1.name, a1.fileName, a1.fqn) IS NOT NULL
  AND coalesce(a2.name, a2.fileName, a2.fqn) IS NOT NULL

RETURN DISTINCT
  // Nombre “amigable” del artefacto 1:
  //  - Maven: name
  //  - Archives / JAR físicos: fileName
  //  - fallback: fqn
  coalesce(a1.name, a1.fileName, a1.fqn) AS Artifact_1_Name,

  // Tipo:
  //  - Maven: type (jar/pom/war/…)
  //  - otros: primer label distinto de 'Artifact' como fallback
  coalesce(
    a1.type,
    head([l IN labels(a1) WHERE l <> 'Artifact'])
  ) AS Artifact_1_Type,

  a1.version AS Artifact_1_Version,

  // Group solo existe en Maven, el resto se queda vacío
  a1.group   AS Artifact_1_Group,

  // Mismo esquema para el artefacto 2
  coalesce(a2.name, a2.fileName, a2.fqn) AS Artifact_2_Name,
  coalesce(
    a2.type,
    head([l IN labels(a2) WHERE l <> 'Artifact'])
  ) AS Artifact_2_Type,
  a2.version AS Artifact_2_Version,
  a2.group   AS Artifact_2_Group

ORDER BY
  Artifact_1_Group, Artifact_1_Name,
  Artifact_2_Group, Artifact_2_Name;
