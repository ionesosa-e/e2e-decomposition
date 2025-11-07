CALL {
MATCH (p:Maven:Project)
RETURN 'Maven Project found' as Info, count(p) as Count
UNION ALL
MATCH (pac:Package)
RETURN 'Packages found' as Info, count(pac) as Count
UNION ALL
MATCH (c:Type:Class)
RETURN 'Classes found' as Info, count(c) as Count
UNION ALL
MATCH (a:Maven:Artifact)
RETURN 'Artifacts found' as Info, count(a) as Count
UNION ALL
MATCH (p:Maven:Plugin)
RETURN 'Plugins found' as Info, count(p) as Count
}
RETURN Info, Count