MATCH (c:Type:Class)-[:ANNOTATED_BY]->(ann:Annotation)-[:OF_TYPE]->(annType:Type)
WHERE annType.fqn IN [
    'org.springframework.security.config.annotation.web.configuration.EnableWebSecurity',
    'org.springframework.security.config.annotation.method.configuration.EnableGlobalMethodSecurity',
    'org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity',
    'org.springframework.context.annotation.Configuration'
]
OPTIONAL MATCH (c)-[:DECLARES]->(m:Method)
WHERE m.name IN ['configure', 'filterChain', 'securityFilterChain', 'authenticationManager']
OPTIONAL MATCH (c)-[:EXTENDS]->(parent:Type)
WHERE parent.name CONTAINS 'WebSecurityConfigurerAdapter'
    OR parent.name CONTAINS 'SecurityConfigurerAdapter'
RETURN c.fqn as SecurityConfigClass,
        COLLECT(DISTINCT annType.name) as Annotations,
        COLLECT(DISTINCT m.name) as ConfigMethods,
        parent.name as ExtendsClass,
        EXISTS((c)-[:EXTENDS]->()) as UsesDeprecatedAdapter
ORDER BY SecurityConfigClass