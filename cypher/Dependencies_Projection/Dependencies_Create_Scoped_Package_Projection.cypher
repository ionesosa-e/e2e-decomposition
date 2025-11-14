// Dependencies_Projection / Dependencies_Create_Scoped_Package_Projection
// Creates a directed in-memory GDS graph for Java package dependencies,
// optionally filtered by $scopePackage. Uses the modern Cypher projection
// based on gds.graph.project as an aggregation function.
//
// Parameters:
//   $dependencies_projection  - base name of the projection (graph name suffix "-cleaned" will be added)
//   $scopePackage             - optional root package for scoping (FQN prefix, e.g. "com.mycompany.myapp")

MATCH (p1:Package)-[d:DEPENDS_ON]->(p2:Package)
WHERE
  $scopePackage IS NULL
  OR trim($scopePackage) = ""
  OR (p1.fqn STARTS WITH $scopePackage AND p2.fqn STARTS WITH $scopePackage)

WITH gds.graph.project(
  $dependencies_projection + '-cleaned',
  p1,                        // source node
  p2,                        // target node
  {
    relationshipProperties: { // relationship properties defined on the in-memory graph
      weight: d.weight       // use the 'weight' property from DEPENDS_ON
    }
  }
) AS g

RETURN
  g.graphName        AS graphName,
  g.nodeCount        AS nodeCount,
  g.relationshipCount AS relationshipCount
