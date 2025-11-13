// High_Level_Architecture / General_Count_Overview
// Global inventory counts for the scanned graph.
// Scope note: global by design (no package-based filtering).

CALL {
  MATCH (p:Maven:Project)
  RETURN 'Maven Project found' AS Info, count(p) AS Count
  UNION ALL
  MATCH (pac:Package)
  RETURN 'Packages found' AS Info, count(pac) AS Count
  UNION ALL
  MATCH (c:Type:Class)
  RETURN 'Classes found' AS Info, count(c) AS Count
  UNION ALL
  MATCH (a:Maven:Artifact)
  RETURN 'Artifacts found' AS Info, count(a) AS Count
  UNION ALL
  MATCH (p:Maven:Plugin)
  RETURN 'Plugins found' AS Info, count(p) AS Count
}
RETURN Info, Count
