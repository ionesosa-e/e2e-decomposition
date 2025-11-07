// Security configurations (flattened for CSV: only scalars)
MATCH (c:Type:Class)-[:ANNOTATED_BY]->(ann:Annotation)-[:OF_TYPE]->(annType:Type)
WHERE annType.fqn IN [
  'org.springframework.security.config.annotation.web.configuration.EnableWebSecurity',
  'org.springframework.security.config.annotation.method.configuration.EnableGlobalMethodSecurity',
  'org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity',
  'org.springframework.context.annotation.Configuration'
]
WITH c, collect(DISTINCT annType.name) AS annNames

// Config methods present
OPTIONAL MATCH (c)-[:DECLARES]->(m:Method)
WHERE m.name IN ['configure','filterChain','securityFilterChain','authenticationManager']
WITH c, annNames, collect(DISTINCT m.name) AS cfgMethods

// Parent types (WebSecurityConfigurerAdapter / SecurityConfigurerAdapter)
OPTIONAL MATCH (c)-[:EXTENDS]->(parent:Type)
WITH c, annNames, cfgMethods, collect(DISTINCT parent.name) AS parentNames

// Joins sin APOC (listas -> string separada por ';')
WITH
  c,
  annNames,
  cfgMethods,
  coalesce(head(parentNames), '') AS extendsClass,
  reduce(s = '', x IN annNames   | s + (CASE WHEN s = '' THEN x ELSE ';' + x END)) AS annotationsJoined,
  reduce(s = '', x IN cfgMethods | s + (CASE WHEN s = '' THEN x ELSE ';' + x END)) AS configMethodsJoined

RETURN
  c.fqn                                       AS securityConfigClass,
  extendsClass                                 AS extendsClass,
  size(annNames)                               AS annotationsCount,
  annotationsJoined                            AS annotations,
  size(cfgMethods)                             AS configMethodsCount,
  configMethodsJoined                          AS configMethods,
  // usa “EXTENDS” para detectar adaptadores antiguos (booleano escalar)
  EXISTS( (c)-[:EXTENDS]->(:Type {name:'WebSecurityConfigurerAdapter'}) )
   OR EXISTS( (c)-[:EXTENDS]->(:Type {name:'SecurityConfigurerAdapter'}) ) AS usesDeprecatedAdapter
ORDER BY securityConfigClass;
