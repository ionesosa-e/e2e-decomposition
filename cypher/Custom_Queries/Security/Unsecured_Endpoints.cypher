MATCH (c:Type:Class)-[:ANNOTATED_BY]->(ctrlAnn:Annotation)-[:OF_TYPE]->(ct:Type)
WHERE ct.fqn IN [
    'org.springframework.stereotype.Controller',
    'org.springframework.web.bind.annotation.RestController'
]

MATCH (c)-[:DECLARES]->(m:Method)-[:ANNOTATED_BY]->(ann:Annotation)-[:OF_TYPE]->(mt:Type)
WHERE mt.fqn IN [
    'org.springframework.web.bind.annotation.GetMapping',
    'org.springframework.web.bind.annotation.PostMapping',
    'org.springframework.web.bind.annotation.PutMapping',
    'org.springframework.web.bind.annotation.DeleteMapping',
    'org.springframework.web.bind.annotation.PatchMapping',
    'org.springframework.web.bind.annotation.RequestMapping'
]

AND NOT EXISTS {
    MATCH (m)-[:ANNOTATED_BY]->(:Annotation)-[:OF_TYPE]->(secType:Type)
    WHERE secType.fqn IN [
        'org.springframework.security.access.prepost.PreAuthorize',
        'org.springframework.security.access.prepost.PostAuthorize',
        'org.springframework.security.access.annotation.Secured',
        'javax.annotation.security.RolesAllowed',
        'javax.annotation.security.PermitAll',
        'jakarta.annotation.security.RolesAllowed',
        'jakarta.annotation.security.PermitAll'
    ]
}

AND NOT EXISTS {
    MATCH (c)-[:ANNOTATED_BY]->(:Annotation)-[:OF_TYPE]->(secType:Type)
    WHERE secType.fqn IN [
        'org.springframework.security.access.prepost.PreAuthorize',
        'org.springframework.security.access.annotation.Secured',
        'javax.annotation.security.RolesAllowed',
        'jakarta.annotation.security.RolesAllowed'
    ]
}

OPTIONAL MATCH (ann)-[:HAS]->(methodContainer:Value)-[:CONTAINS]->(methodPathVal:Value)
WHERE methodContainer.name IN ["value", "path"]

OPTIONAL MATCH (ctrlAnn)-[:HAS]->(ctrlContainer:Value)-[:CONTAINS]->(ctrlPathVal:Value)
WHERE ctrlContainer.name IN ["value", "path"]

RETURN
    c.fqn AS Controller,
    m.name AS Method,
    mt.name AS HttpMethod,
    COALESCE(ctrlPathVal.value, '') + COALESCE(methodPathVal.value, '') AS CompleteEndpoint,
    'POTENTIALLY_UNSECURED' AS SecurityStatus
ORDER BY Controller, Method