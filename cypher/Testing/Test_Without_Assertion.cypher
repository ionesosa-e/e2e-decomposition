MATCH (t:Test:Method)
WHERE NOT (t)-[:INVOKES]->(:Assert:Method)
RETURN t AS TestWithoutAssertion