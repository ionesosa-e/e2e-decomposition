# 🧩 E2E Code Decomposition Pipeline

This repository provides an automated **end-to-end analysis pipeline**
that scans a Java project using **jQAssistant**, stores results in
**Neo4j**, and generates **CSV reports** and **HTML notebook
visualizations** --- all with **one single command**.

------------------------------------------------------------------------

# 🚀 Run Everything (One Command)

``` bash
scripts/pipeline-run-all.sh
```

This command will:

-   Create `scripts/env.sh` if missing (from `env-example.sh`)
-   Set up Python virtualenv and dependencies
-   Start Neo4j and validate connectivity
-   Run jQAssistant scan over the target project
-   Generate **all CSV reports** from Cypher queries
-   Execute **all Jupyter notebooks** and export them to HTML
-   Generate an index page at `reports/notebooks/index.html`

Once completed, results are located in:

-   **CSV reports:** `reports/csv-reports/`
-   **Notebook HTML reports:** `reports/notebooks/`

------------------------------------------------------------------------

# ⚙️ Configuration

All environment variables are controlled through:

    scripts/env.sh

If this file does not exist, the pipeline creates it automatically.

You may adjust:

-   Neo4j credentials and ports\
-   Output folder for reports\
-   Project path to analyze (`REPO_TO_ANALYZE`)\
-   Flags to skip certain stages\
-   Notebook output directory

The file:

    config/analysis-scope.json

allows optional scoping of the analysis (e.g., filtering by package
prefix).

------------------------------------------------------------------------

# 🔧 Optional Flags

These environment variables change pipeline behavior:

  Variable                Description                          Default
  ----------------------- ------------------------------------ ---------
  `E2E_SKIP_SETUP`        Skip Python/jq setup                 `false`
  `E2E_SKIP_NEO4J`        Skip Neo4j startup/setup             `false`
  `E2E_SKIP_JQA`          Skip jQAssistant scan                `false`
  `E2E_SKIP_CSV`          Skip CSV reports                     `false`
  `E2E_SKIP_NOTEBOOKS`    Skip notebook execution              `false`
  `E2E_STOP_NEO4J`        Stop Neo4j at end                    `false`
  `E2E_AUTO_INSTALL_JQ`   Install jq via Homebrew if missing   `false`

Use these in `scripts/env.sh` or export them before running the
pipeline.

------------------------------------------------------------------------

# 🧠 What the Pipeline Does Internally

When running `pipeline-run-all.sh`, the following internal flow is
executed:

1.  **Environment Setup**
    -   Validates presence of `jq`, `python3`, and `jupyter`.
    -   Creates and activates a `.venv` virtual environment.
    -   Installs Python requirements.
2.  **Neo4j Initialization**
    -   Sets up Neo4j directories.
    -   Starts Neo4j.
    -   Performs a smoke test.
3.  **jQAssistant Scan**
    -   Downloads & configures jQAssistant (if needed).
    -   Scans the target project (JAR or source tree).
    -   Stores results in the Neo4j graph database.
4.  **CSV Report Generation**
    -   Executes **all Cypher queries** under `cypher/**`.

    -   Writes CSV output for each category into:

            reports/csv-reports/<Category>/
5.  **Notebook Visualization**
    -   Runs all notebooks in `jupyter/`.

    -   Exports HTML visualizations to:

            reports/notebooks/<NotebookName>/

    -   Builds an auto-generated index at:

            reports/notebooks/index.html

------------------------------------------------------------------------

# 🧩 Stopping Neo4j

If the database remains running and you want to stop it:

``` bash
scripts/neo4j/neo4j-stop.sh
```

------------------------------------------------------------------------

# ✅ Summary

To analyze a Java project and generate all reports:

``` bash
scripts/pipeline-run-all.sh
```

Outputs will be available under:

-   `reports/csv-reports/`
-   `reports/notebooks/`

Everything is automated --- from environment setup to graph analysis and
visualization.

Enjoy exploring your codebase! 🚀
