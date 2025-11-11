import pandas as pd
from pathlib import Path
import textwrap

# Base folders for CSV reports
CSV_BASE = Path(__file__).parent.parent.parent / "reports" / "custom-queries-csv"

def read_csv_safe(path: Path) -> pd.DataFrame:
    """Read a CSV if present; otherwise return an empty DataFrame.
    Prints a minimal info message when missing or unreadable."""
    path = Path(path)
    if not path.exists():
        print(f"[info] Missing CSV: {path}")
        return pd.DataFrame()
    try:
        df = pd.read_csv(path)
        df.columns = [str(c).strip() for c in df.columns]
        return df
    except Exception as e:
        print(f"[warn] Failed to read {path}: {e}")
        return pd.DataFrame()

def show_head(df: pd.DataFrame, n: int = 8):
    """Display a quick head for ad‑hoc inspection; silent if empty."""
    if df.empty:
        print("[info] DataFrame is empty.")
    else:
        print(df.head(n))

def shorten_label(s: str, maxlen: int = 40) -> str:
    """Shorten a label to maxlen characters, adding ellipsis if needed."""
    s = str(s)
    return (s[:maxlen-1] + "…") if len(s) > maxlen else s

def wrap_label_html(s: str, width: int = 28) -> str:
    """Wrap a label with HTML line breaks for better display."""
    return "<br>".join(textwrap.wrap(str(s), width=width))

def fillna_safe(series, value):
    """Mask NA values with a given literal without triggering downcast warnings."""
    s = series.copy()
    s = s.mask(s.isna(), value)
    return s

def get_csv_path(category: str, filename: str) -> Path:
    """Get the full path to a CSV file in the reports directory."""
    return CSV_BASE / category / filename
