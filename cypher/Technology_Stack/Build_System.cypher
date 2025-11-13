// Technology_Stack / Build_System
// Attempts to detect the build system from the scanned graph.
// Scope note: global by design (no package-based filtering).
// NOTE: This might be easier and more robust to determine outside of jQAssistant,
//       but it is kept here for completeness.

CALL {
  MATCH (project:Maven:Project)
  RETURN
    'Maven' AS BuildSystem,
    project.groupId + ':' + project.artifactId AS ProjectName,
    project.version AS ProjectVersion,
    project.packaging AS Packaging
  LIMIT 1

  UNION ALL

  MATCH (project:Gradle:Project)
  RETURN
    'Gradle' AS BuildSystem,
    project.name AS ProjectName,
    project.version AS ProjectVersion,
    'jar' AS Packaging
  LIMIT 1
}
RETURN BuildSystem, ProjectName, ProjectVersion, Packaging
