// Dependencies / External_Dependencies
// Inventory of all artifacts present in the scanned graph.
// Scope note: global by design (no package-based filtering).

MATCH (artifact:Artifact)
RETURN DISTINCT
  artifact.group,
  artifact.name,
  artifact.version
ORDER BY artifact.group