// Path Finding - Longest path - Stream - List all dependencies for nodes contributing to longest paths
// Adapted: does NOT rely on maxDistanceFromSource (uses only name / fqn for titles).

// Gather global statistics about dependency weights for normalization
MATCH (sourceNodeForStatistics)-[dependencyForStatistics:DEPENDS_ON]->(targetNodeForStatistics)
WHERE $dependencies_projection_node IN LABELS(sourceNodeForStatistics)
  AND $dependencies_projection_node IN LABELS(targetNodeForStatistics)
WITH
  min(dependencyForStatistics[$dependencies_projection_weight_property]) AS minWeight,
  max(dependencyForStatistics[$dependencies_projection_weight_property]) AS maxWeight
WITH
  minWeight,
  maxWeight,
  CASE
    WHEN maxWeight = minWeight THEN 1.0
    ELSE 1.0 / toFloat(maxWeight - minWeight)
  END AS weightNormalizationFactor
WITH { minWeight: minWeight, weightNormalizationFactor: weightNormalizationFactor } AS statistics

// -> Main call to execute "longest path" algorithm
CALL gds.dag.longestPath.stream($dependencies_projection + '-cleaned')
YIELD index, totalCost, path
WITH statistics, index, totalCost, path
// Sort longest paths by their length descending and - if equal - by their index ascending
ORDER BY totalCost DESC, index ASC
// Only take the top N longest paths as a compromise between performance and visualization content
LIMIT $pathLimit

// Collect all results of the longest path search as well as all nodes of the longest paths
WITH
  statistics,
  collect({index: index, distance: toInteger(totalCost), path: path}) AS longestPaths,
  collect(nodes(path)) AS allLongestPathNodes

// Flatten and deduplicate the list of all nodes that contribute to at least one longest path
UNWIND allLongestPathNodes AS longestPathNodes
UNWIND longestPathNodes    AS longestPathNode
WITH
  statistics,
  longestPaths,
  collect(DISTINCT longestPathNode) AS allDistinctLongestPathNodes

// Iterate over all longest paths
UNWIND longestPaths AS longestPath
WITH
  statistics,
  longestPaths,
  allDistinctLongestPathNodes,
  [ rel IN relationships(longestPath.path)     | [startNode(rel), endNode(rel)] ] AS allLongestPathStartAndEndNodeTuples,
  [ rel IN relationships(longestPaths[0].path) | [startNode(rel), endNode(rel)] ] AS longestPathStartAndEndNodeTuples,
  longestPath.index    AS index,
  longestPath.distance AS distance

// -> Main query of all dependencies of nodes contributing to the longest paths
MATCH (source)-[dependency:DEPENDS_ON]->(target)
WHERE $dependencies_projection_node IN labels(source)
  AND $dependencies_projection_node IN labels(target)
  // Dependent nodes need to be part of at least one longest path
  AND (source IN allDistinctLongestPathNodes AND target IN allDistinctLongestPathNodes)

WITH
  statistics.minWeight                 AS minWeight,
  statistics.weightNormalizationFactor AS weightNormalizationFactor,
  count(index)                         AS numberOfLongestPathsPassing,
  max(distance)                        AS lengthOfLongestPathPassing,
  dependency,
  source,
  target,
  // If there is at least one longest path passing through the dependency then "contributesToALongestPath" is true
  ([source, target] IN allLongestPathStartAndEndNodeTuples) AS contributesToALongestPath,
  ([source, target] IN longestPathStartAndEndNodeTuples)    AS isPartOfLongestPath

WITH *,
  dependency[$dependencies_projection_weight_property] AS weight

WITH *,
  toFloat(weight - minWeight) * weightNormalizationFactor AS normalizedWeight

WITH *,
  CASE
    WHEN normalizedWeight < 0.33 THEN 1.0   // relaciones débiles
    WHEN normalizedWeight < 0.66 THEN 3.0   // medias
    ELSE 6.0                                // muy fuertes
  END AS penWidth


// Node titles without maxDistanceFromSource (just name or fqn)
WITH *,
  CASE
    WHEN $scopePackage IS NOT NULL
         AND trim($scopePackage) <> ""
         AND source.fqn STARTS WITH $scopePackage
      THEN replace(source.fqn, $scopePackage + ".", "")
    ELSE coalesce(source.fqn, source.name)
  END AS startNodeTitle,
  CASE
    WHEN $scopePackage IS NOT NULL
         AND trim($scopePackage) <> ""
         AND target.fqn STARTS WITH $scopePackage
      THEN replace(target.fqn, $scopePackage + ".", "")
    ELSE coalesce(target.fqn, target.name)
  END AS endNodeTitle,
  CASE
    WHEN isPartOfLongestPath       THEN "; color=\"red\""        // longest path edges
    WHEN contributesToALongestPath THEN "; color=\"darkorange\"" // contributing edges
    ELSE "" END AS edgeColor



// Prepare the GraphViz edge attributes for the visualization
WITH *,
  "[label=" + weight  + "; penwidth=" + penWidth + edgeColor + "; ];" AS graphVizEdgeAttributes

// Assemble the final GraphViz DOT notation line for the edge representing the current dependency
WITH *,
  "\"" + startNodeTitle +  "\" -> \"" + endNodeTitle + "\" " + graphVizEdgeAttributes AS graphVizDotNotationLine

RETURN DISTINCT graphVizDotNotationLine
LIMIT 440
