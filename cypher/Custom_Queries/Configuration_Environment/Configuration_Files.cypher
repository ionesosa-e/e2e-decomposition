MATCH (f:File)
WHERE f.name ENDS WITH '.yml'
OR f.name ENDS WITH '.yaml'
OR f.name ENDS WITH '.properties'
RETURN f AS configurationFile