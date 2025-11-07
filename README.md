# 🧩 E2E Code Decomposition Pipeline

This repository provides an **end-to-end analysis pipeline** to decompose large software java systems into graph structures, using **jQAssistant**, **Neo4j**, and **Jupyter Notebooks**.

The goal is to:
- Scan and extract metadata from source code.
- Store relationships (packages, types, dependencies) in a Neo4j graph database.
- Generate CSV reports with Cypher queries.
- Visualize metrics and structure insights through Jupyter notebooks.

---

## 🧱 Requirements

Before starting, make sure you have the following tools installed on your machine (macOS / Linux):

```bash
brew install jq
brew install python
```

> 🧠 **Note:** `jq` is used for JSON parsing in jQAssistant setup and `neo4j` must be accessible locally.

---

## ⚙️ Environment Setup

### 1️⃣ Source environment variables
Make sure environment variables are properly loaded:

```bash
source scripts/env.sh
```

---

### 2️⃣ Initialize the Neo4j database
Create a new clean Neo4j database with indexes and plugins configured for jQAssistant:

```bash
scripts/setupNeo4j.sh
```

---

### 3️⃣ Start the Neo4j server
Start Neo4j locally to allow connections through the `bolt://localhost:7687` endpoint:

```bash
scripts/neo4j-start.sh
```

---

### 4️⃣ (Optional) Smoke test the database
You can validate Neo4j connectivity and plugin readiness using:

```bash
scripts/neo4j-smoketest.sh
```

This performs a lightweight Cypher test query to verify that the database is reachable.

---

### 5️⃣ Setup jQAssistant
Prepare the jQAssistant runtime environment and ensure all plugins are available:

```bash
scripts/setupJQAssistant.sh
```

This step installs necessary plugins.

---

### 6️⃣ Run jQAssistant with remote database configuration
Run the static analysis for your target repository (e.g., `repo-to-refactor_test/jBilling`):

```bash
scripts/jqa-run-remote.sh
```

This performs the source code scan, rule evaluation, and stores the analyzed model into Neo4j.

---

## 📊 Generate CSV Reports

Once jQAssistant has populated the Neo4j database, generate CSV reports for multiple analysis domains:

```bash
scripts/reports/compilations/CsvReports.sh
```

This command orchestrates all reporting scripts and exports the results to `/reports/`.

---

### Reports generated include:

| Category | Script | Output Directory |
|-----------|---------|------------------|
| Overview | `scripts/reports/OverviewCsv.sh` | `reports/overview-csv/` |
| Java | `scripts/reports/JavaCsv.sh` | `reports/java-csv/` |
| Metrics | `scripts/reports/MetricsCsv.sh` | `reports/metrics-csv/` |
| Artifact Dependencies | `scripts/reports/ArtifactDependenciesCsv.sh` | `reports/artifact-dependencies-csv/` |

Each of these scripts executes a set of Cypher queries from the corresponding subdirectory in `/cypher`.

---

## 🧮 (Coming Soon) Jupyter Notebooks

When the Jupyter notebooks are ready, you’ll be able to generate interactive visualizations by running:

```bash
scripts/reports/compilations/JupyterReports.sh
```

Each notebook (e.g., `OverviewGeneral.ipynb`, `OverviewJava.ipynb`) will visualize the CSV data previously generated, including charts, bar plots, and graph metrics.

---

## 🧩 Stop Neo4j Server

When finished, stop the local Neo4j instance cleanly:

```bash
scripts/neo4j-stop.sh
```

---

## 🔍 End-to-End Execution Flow

Below is a **detailed technical flow** describing how the system connects all its components.

```text
1. scripts/env.sh
   ├── Exports environment variables:
   │     NEO4J_HOME
   │     NEO4J_USERNAME
   │     NEO4J_INITIAL_PASSWORD
   │     REPO_PATH
   │     CYPHER_DIR
   │     REPORTS_DIRECTORY
   └── Makes paths accessible to all scripts

2. scripts/setupNeo4j.sh
   ├── Initializes Neo4j directories under $NEO4J_HOME
   ├── Configures plugins for remote Bolt access
   ├── Creates indexes and basic constraints
   └── Ensures the database is ready for imports

3. scripts/neo4j-start.sh
   └── Launches the Neo4j database server (background daemon)

4. scripts/neo4j-smoketest.sh (optional)
   └── Uses cypher-shell to run a test query `MATCH (n) RETURN count(n)`

5. scripts/setupJQAssistant.sh
   ├── Downloads and configures jqassistant-cli.jar
   ├── Installs required plugins (Spring, OpenAPI, TypeScript)
   ├── Sets up configuration in jqassistant.yml
   └── Validates installation

6. scripts/jqa-run-remote.sh
   ├── Calls jQAssistant CLI using:
   │     java -jar jqassistant-cli.jar scan --store <bolt://localhost:7687>
   ├── Scans the target source repository for artifacts
   ├── Stores nodes and relationships in Neo4j
   └── Generates summary logs in runtime/jqassistant/report/

7. scripts/reports/compilations/CsvReports.sh
   ├── Invokes the following report groups sequentially:
   │     a. scripts/reports/OverviewCsv.sh
   │     b. scripts/reports/JavaCsv.sh
   │     c. scripts/reports/MetricsCsv.sh
   │     d. scripts/reports/ArtifactDependenciesCsv.sh
   ├── Each script internally calls:
   │     source scripts/executeQueryFunctions.sh
   │     → provides helper `execute_cypher <file.cypher>`
   ├── Each report script:
   │     - Resolves directories (repo root, cypher, reports)
   │     - Executes queries via cypher-shell
   │     - Exports results as CSV files into `reports/<category>-csv/`
   └── When all are done, the pipeline outputs:
         /reports/
            ├── overview-csv/
            ├── java-csv/
            ├── metrics-csv/
            └── artifact-dependencies-csv/

8. scripts/reports/compilations/JupyterReports.sh  (future step)
   ├── Calls executeJupyterNotebookReport.sh for each .ipynb file
   ├── Each notebook:
   │     - Reads CSVs from reports/
   │     - Generates markdown and PDF
   └── Uses Python virtual environment configured by:
         scripts/activatePythonEnvironment.sh

9. scripts/neo4j-stop.sh
   └── Stops Neo4j database cleanly and frees the port 7687
```

---

## 🧠 Example Full Workflow

```bash
# Prepare environment
source scripts/env.sh
scripts/setupNeo4j.sh
scripts/neo4j-start.sh
scripts/setupJQAssistant.sh
scripts/jqa-run-remote.sh

# Generate analytical CSV reports
scripts/reports/compilations/CsvReports.sh

# (Optional) Launch Jupyter reports when available
scripts/reports/compilations/JupyterReports.sh

# Stop database
scripts/neo4j-stop.sh
```


---

