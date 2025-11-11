MATCH (c:Class)-[:DEPENDS_ON]->(a:Artifact)
WHERE (
    a.name =~ '(?i).*(-sdk|-client-java|-rest-client|-api-client).*'
    OR a.group IN [
        'com.amazonaws', 'com.microsoft.azure', 'com.google.cloud',
        'com.stripe', 'com.twilio', 'com.sendgrid'
    ]
    OR a.group CONTAINS '.http.client'
)
AND NOT a.group IN ['org.apache.httpcomponents', 'com.squareup.okhttp3']
AND NOT a.name IN ['mysql-connector-java', 'postgresql', 'mariadb-java-client']
RETURN DISTINCT c.name as className, a.group as artifactGroup, a.name as artifactName, a.version as artifactVersion
ORDER BY a.group, a.name