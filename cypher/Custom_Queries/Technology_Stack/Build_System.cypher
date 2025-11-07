//CREO QUE ESTO SE PUEDE HACER MEJOR SIN JQAssistant, mas facil y seguro

CALL {
    MATCH (project:Maven:Project)
    RETURN
        'Maven' as BuildSystem,
        project.groupId + ':' + project.artifactId as ProjectName,
        project.version as ProjectVersion,
        project.packaging as Packaging
    LIMIT 1

    UNION ALL

    MATCH (project:Gradle:Project)
    RETURN
        'Gradle' as BuildSystem,
        project.name as ProjectName,
        project.version as ProjectVersion,
        'jar' as Packaging
    LIMIT 1
}
RETURN BuildSystem, ProjectName, ProjectVersion, Packaging