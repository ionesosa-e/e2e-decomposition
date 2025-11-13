// Technology_Stack / Java_Version
// Infers Java version from the byteCodeVersion of compiled classes.
// Scope note: global by design; no package-based filtering is applied.
// NOTE: This might be easier to determine from build metadata outside jQAssistant,
//       but it is kept here for completeness.

MATCH (c:Type:Class)
WITH c.byteCodeVersion AS bytecodeVersion
RETURN
  CASE bytecodeVersion
    WHEN 52 THEN '8'
    WHEN 53 THEN '9'
    WHEN 54 THEN '10'
    WHEN 55 THEN '11'
    WHEN 56 THEN '12'
    WHEN 57 THEN '13'
    WHEN 58 THEN '14'
    WHEN 59 THEN '15'
    WHEN 60 THEN '16'
    WHEN 61 THEN '17'
    WHEN 62 THEN '18'
    WHEN 63 THEN '19'
    WHEN 64 THEN '20'
    WHEN 65 THEN '21'
    ELSE 'Unknown'
  END AS JavaVersionFromBytecode
LIMIT 1
