// Configuration_Environment / Configuration_Files
// Lists configuration files by common extensions. Global by design.
// Scope note: no package-based filtering applied.

MATCH (f:File)
WHERE f.name ENDS WITH '.yml'
   OR f.name ENDS WITH '.yaml'
   OR f.name ENDS WITH '.properties'
RETURN f AS configurationFile
