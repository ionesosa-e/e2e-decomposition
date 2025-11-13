// External_Integration / External_SDKs
// Finds classes that depend on likely external SDKs/clients.
// Optional scope: when $scopePackage is provided (non-empty), limit to classes whose FQN starts with that prefix.
// If $scopePackage is empty or null, no filtering is applied (full project).

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
AND (
    $scopePackage IS NULL OR trim($scopePackage) = "" OR c.fqn STARTS WITH $scopePackage
)
RETURN DISTINCT
  c.name  AS className,
  a.group AS artifactGroup,
  a.name  AS artifactName,
  a.version AS artifactVersion
ORDER BY a.group, a.name
