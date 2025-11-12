import pandas as pd
import numpy as np
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

def labelize_na(s, label="N/A"):
    """Replace NA-like values with a visible label for categorical charts."""
    s = s.copy()
    s = s.mask(s.isna(), label).astype(str)
    s = s.replace({"nan": label, "NaN": label})
    return s

def pick_col(df, names=None, kind=None):
    """Pick a useful column by preference list or dtype kind ('numeric' | 'text')."""
    names = names or []
    by_lower = {c.lower(): c for c in df.columns}
    if kind == "numeric":
        nums = list(df.select_dtypes(include=[np.number]).columns)
        return nums[0] if nums else None
    if kind == "text":
        objs = [c for c in df.columns if df[c].dtype == "object"]
        return objs[0] if objs else (df.columns[0] if len(df.columns) else None)
    for n in names:
        got = by_lower.get(n.lower())
        if got:
            return got
    return None

def ext_from_name(x: str) -> str:
    """Derive a file extension from a filename/path; 'unknown' if none."""
    s = str(x)
    if "." in s:
        return s.split(".")[-1].lower()
    return "unknown"


def find_col(df, *cands, default=None, contains=None):
    """Find a column by exact candidates or by substring (contains)."""
    low = {c.lower(): c for c in df.columns}
    for c in cands:
        if c and c.lower() in low:
            return low[c.lower()]
    if contains:
        for k, orig in low.items():
            if contains.lower() in k:
                return orig
    return default