MATCH (artifact:Artifact)
RETURN DISTINCT artifact.group, artifact.name, artifact.version
ORDER BY artifact.group