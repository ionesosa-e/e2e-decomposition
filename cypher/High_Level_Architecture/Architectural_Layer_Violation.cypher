// High_Level_Architecture / Architectural_Layer_Violation
// Detects controllers that directly depend on repositories, bypassing the service layer.
// Optional scope: when $scopePackage is provided (non-empty),
// only consider controllers whose FQN starts with that prefix.
// If $scopePackage is empty or null, no filtering is applied (full project).

MATCH (controller:Type)-[:DEPENDS_ON]->(repository:Type)
WHERE
  (
    controller.fqn =~ '(?i).*\\.controller\\..*'
    OR EXISTS {
      MATCH (controller)-[:ANNOTATED_BY]->(:Annotation)-[:OF_TYPE]->(ct:Type)
      WHERE ct.fqn IN [
        'org.springframework.stereotype.Controller',
        'org.springframework.web.bind.annotation.RestController'
      ]
    }
  )
  AND (
    repository.fqn =~ '(?i).*\\.repository\\..*'
    OR EXISTS {
      MATCH (repository)-[:ANNOTATED_BY]->(:Annotation)-[:OF_TYPE]->(rt:Type)
      WHERE rt.fqn = 'org.springframework.stereotype.Repository'
         OR rt.name CONTAINS 'Repository'
    }
  )
  AND (
    $scopePackage IS NULL OR trim($scopePackage) = "" OR controller.fqn STARTS WITH $scopePackage
  )
  AND NOT EXISTS {
    MATCH (controller)-[:DEPENDS_ON]->(service:Type)-[:DEPENDS_ON]->(repository)
    WHERE
      service.fqn =~ '(?i).*\\.service\\..*'
      OR EXISTS {
        MATCH (service)-[:ANNOTATED_BY]->(:Annotation)-[:OF_TYPE]->(st:Type)
        WHERE st.fqn = 'org.springframework.stereotype.Service'
      }
  }

RETURN DISTINCT
  controller.fqn AS Controller,
  repository.fqn AS Repository,
  'LAYER_VIOLATION: Controller bypasses Service layer' AS Violation
ORDER BY Controller
