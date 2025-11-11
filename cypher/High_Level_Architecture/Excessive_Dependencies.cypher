MATCH (t:Type)-[d:DEPENDS_ON]->() WITH t, count(d) as dependencies WHERE dependencies > 15 RETURN
t.fqn as classFqn,dependencies ORDER BY dependencies DESC