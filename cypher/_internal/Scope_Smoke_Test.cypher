// Verifies APOC can read analysis-scope.json from neo4j/import
CALL apoc.load.jsonParams("file:///analysis-scope.json", null, null) YIELD value
RETURN
  coalesce(value.input_path, '(none)')  AS input_path,
  coalesce(value.output_path, '(none)') AS output_path,
  coalesce(value.packages, [])          AS packages,
  size(coalesce(value.packages, []))    AS packages_count;
