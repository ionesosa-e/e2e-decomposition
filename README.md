# 🧩 E2E Code Decomposition Pipeline

This repository provides an **end-to-end automated pipeline** that scans, analyzes, and visualizes Java codebases as graph structures using **jQAssistant**, **Neo4j**, and **Jupyter Notebooks**.

The entire process — from setup to report generation — can now be executed with **a single command**:

```bash
scripts/pipeline-run-all.sh
```

---

## 🚀 Overview

The pipeline automatically performs the following steps:

1. **Environment setup**
   - Ensures dependencies like `jq`, `python3`, and `jupyter` are available.
   - Creates and activates a Python virtual environment (`.venv`).
   - Installs required Python packages.

2. **Neo4j setup**
   - Initializes, starts, and validates a Neo4j instance.
   - Runs a lightweight smoke test to confirm connectivity.

3. **jQAssistant scan**
   - Installs or updates jQAssistant.
   - Scans the target project and stores graph data in Neo4j.

4. **CSV report generation**
   - Executes all Cypher-based reports in `/cypher/**`.
   - Exports structured CSVs under:
     ```
     reports/csv-reports/<Category>/
     ```

5. **Notebook visualization**
   - Executes all Jupyter notebooks from `/jupyter/`.
   - Generates interactive **HTML reports** in:
     ```
     reports/notebooks/<NotebookName>/<NotebookName>.html
     ```
   - Creates an automatic HTML index at:
     ```
     reports/notebooks/index.html
     ```

---

## ⚙️ Configuration

All environment variables and paths are controlled through:

```
scripts/env.sh
```

If it doesn’t exist, the pipeline will **automatically create it** from:

```
scripts/env-example.sh
```

You can modify this file to customize:
- Neo4j ports, credentials, and directories.
- Output folders for CSV and notebook reports.
- Feature flags (e.g., skip steps, enable/disable notebook formats).

---

## 🔧 Optional Flags

You can control pipeline stages via environment variables in `.env` or `.bashrc`:

| Variable | Description | Default |
|-----------|--------------|----------|
| `E2E_SKIP_SETUP` | Skip Python/jq setup | `false` |
| `E2E_SKIP_NEO4J` | Skip Neo4j start/setup | `false` |
| `E2E_SKIP_JQA` | Skip jQAssistant scan | `false` |
| `E2E_SKIP_CSV` | Skip CSV reports | `false` |
| `E2E_SKIP_NOTEBOOKS` | Skip Jupyter notebooks | `false` |
| `E2E_STOP_NEO4J` | Stop Neo4j when done | `false` |
| `E2E_AUTO_INSTALL_JQ` | Auto-install jq via Homebrew if missing | `false` |

---

## 📁 Output Structure

After successful execution, results are organized as follows:

```
reports/
├── csv-reports/
│   ├── API_Entry_Points/
│   ├── Configuration_Environment/
│   ├── Database/
│   └── ...
└── notebooks/
    ├── API_Entry_Points/
    │   ├── API_Entry_Points.html
    │   └── API_Entry_Points.ipynb
    └── index.html
```

---

## 🧠 Flow Summary

```text
pipeline-run-all.sh
 ├── Ensures environment (creates env.sh if missing)
 ├── Sets up Python virtualenv and installs dependencies
 ├── Runs setup/start for Neo4j
 ├── Executes jQAssistant (scan + store in Neo4j)
 ├── Runs all Cypher-based CSV report scripts
 ├── Executes all Jupyter notebooks (HTML by default)
 └── Builds reports/notebooks/index.html
```

---

## ✅ One Command to Run Everything

Simply execute:

```bash
scripts/pipeline-run-all.sh
```

This will:
- Create `scripts/env.sh` (if missing).
- Prepare and start Neo4j.
- Run jQAssistant analysis.
- Generate CSV and HTML reports.
- Build a navigable HTML index located at:
  ```
  reports/notebooks/index.html
  ```

Once done, check:

- CSV reports → `reports/csv-reports/`
- Jupyter visualizations → `reports/notebooks/`

---

## 🧩 Stop Neo4j Manually (Optional)

If Neo4j is still running and you wish to stop it:

```bash
scripts/neo4j/neo4j-stop.sh
```

---

**Author:** Internal DevTools Automation  
**Version:** E2E Decomposition Pipeline — Unified Execution  
**License:** Internal / Research Use
