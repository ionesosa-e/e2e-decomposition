// Security / Security_Configurations
// Security configuration classes (flattened for CSV: scalar-only columns).
// Optional scope: when $scopePackage is provided (non-empty),
// limit to classes whose FQN starts with that prefix.
// If $scopePackage is empty or null, no filtering is applied (full project).

MATCH (c:Type:Class)-[:ANNOTATED_BY]->(ann:Annotation)-[:OF_TYPE]->(annType:Type)
WHERE
  annType.fqn IN [
    'org.springframework.security.config.annotation.web.configuration.EnableWebSecurity',
    'org.springframework.security.config.annotation.method.configuration.EnableGlobalMethodSecurity',
    'org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity',
    'org.springframework.context.annotation.Configuration'
  ]
  AND (
    $scopePackage IS NULL OR trim($scopePackage) = "" OR c.fqn STARTS WITH $scopePackage
  )
WITH c, collect(DISTINCT annType.name) AS annNames

// Configuration methods present
OPTIONAL MATCH (c)-[:DECLARES]->(m:Method)
WHERE m.name IN ['configure','filterChain','securityFilterChain','authenticationManager']
WITH c, annNames, collect(DISTINCT m.name) AS cfgMethods

// Parent types (WebSecurityConfigurerAdapter / SecurityConfigurerAdapter)
OPTIONAL MATCH (c)-[:EXTENDS]->(parent:Type)
WITH c, annNames, cfgMethods, collect(DISTINCT parent.name) AS parentNames

// Joins without APOC (lists -> ';'-separated string)
WITH
  c,
  annNames,
  cfgMethods,
  coalesce(head(parentNames), '') AS extendsClass,
  reduce(s = '', x IN annNames   | s + (CASE WHEN s = '' THEN x ELSE ';' + x END)) AS annotationsJoined,
  reduce(s = '', x IN cfgMethods | s + (CASE WHEN s = '' THEN x ELSE ';' + x END)) AS configMethodsJoined

RETURN
  c.fqn          AS securityConfigClass,
  extendsClass   AS extendsClass,
  size(annNames) AS annotationsCount,
  annotationsJoined AS annotations,
  size(cfgMethods)  AS configMethodsCount,
  configMethodsJoined AS configMethods,
  // uses “EXTENDS” to detect older adapter-based configurations (boolean scalar)
  EXISTS( (c)-[:EXTENDS]->(:Type {name:'WebSecurityConfigurerAdapter'}) )
   OR EXISTS( (c)-[:EXTENDS]->(:Type {name:'SecurityConfigurerAdapter'}) ) AS usesDeprecatedAdapter
ORDER BY securityConfigClass;
