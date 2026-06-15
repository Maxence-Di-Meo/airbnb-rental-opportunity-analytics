from __future__ import annotations

import os
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_MANIFEST_PATH = PROJECT_ROOT / "config" / "source_manifest.yml"
DATA_ROOT = PROJECT_ROOT / "data"
EXTERNAL_ROOT = DATA_ROOT / "external"
LAKE_ROOT = DATA_ROOT / "lake"


def env(name: str, default: str | None = None) -> str:
    value = os.getenv(name, default)
    if value is None:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def postgres_url() -> str:
    user = env("POSTGRES_USER", "airbnb")
    password = env("POSTGRES_PASSWORD", "airbnb")
    host = env("POSTGRES_HOST", "localhost")
    port = env("POSTGRES_PORT", "5432")
    database = env("POSTGRES_DB", "airbnb_invest")
    return f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{database}"
