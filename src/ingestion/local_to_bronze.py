from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path
import re

import h3
import pandas as pd
import yaml

from src.utils.settings import PROJECT_ROOT


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Load local public datasets into bronze parquet files.")
    parser.add_argument("--manifest", required=True, help="Path to YAML manifest describing local source files.")
    parser.add_argument(
        "--snapshot-date",
        default=datetime.utcnow().strftime("%Y-%m-%d"),
        help="Logical snapshot date used in bronze partitioning.",
    )
    return parser.parse_args()


def load_manifest(manifest_path: Path) -> dict:
    with manifest_path.open("r", encoding="utf-8") as stream:
        return yaml.safe_load(stream)


def normalize_column(name: str) -> str:
    normalized = re.sub(r"[^a-zA-Z0-9]+", "_", name.strip().lower())
    return normalized.strip("_")


def discover_files(path_glob: str) -> list[Path]:
    pattern = PROJECT_ROOT / path_glob
    candidates = sorted(pattern.parent.glob(pattern.name))
    return [
        path
        for path in candidates
        if path.is_file() and not path.name.startswith(".") and path.stat().st_size > 0
    ]


def read_dataframe(file_path: Path, dataset_cfg: dict) -> pd.DataFrame:
    fmt = dataset_cfg.get("format", "csv")
    delimiter = dataset_cfg.get("delimiter", ",")

    if fmt == "csv":
        return pd.read_csv(file_path, sep=delimiter, low_memory=False)
    if fmt == "parquet":
        return pd.read_parquet(file_path)

    raise ValueError(f"Unsupported file format for {file_path}: {fmt}")


def maybe_add_h3_columns(frame: pd.DataFrame) -> pd.DataFrame:
    lat_col = "latitude" if "latitude" in frame.columns else None
    lon_col = "longitude" if "longitude" in frame.columns else None

    if lat_col and lon_col:
        latitude = pd.to_numeric(frame[lat_col], errors="coerce")
        longitude = pd.to_numeric(frame[lon_col], errors="coerce")

        def to_cell(lat: float, lon: float, resolution: int) -> str | None:
            if pd.isna(lat) or pd.isna(lon):
                return None
            return h3.latlng_to_cell(float(lat), float(lon), resolution)

        frame["h3_res8"] = [to_cell(lat, lon, 8) for lat, lon in zip(latitude, longitude)]
        frame["h3_res9"] = [to_cell(lat, lon, 9) for lat, lon in zip(latitude, longitude)]

    return frame


def ingest_dataset(dataset_name: str, dataset_cfg: dict, snapshot_date: str) -> tuple[str, int]:
    files = discover_files(dataset_cfg["path_glob"])

    if dataset_cfg.get("required_for_mvp", False) and not files:
        raise FileNotFoundError(
            f"Required dataset '{dataset_name}' not found. Expected files matching: {dataset_cfg['path_glob']}"
        )

    written = 0
    bronze_dir = PROJECT_ROOT / "data" / "lake" / "bronze" / dataset_name / f"snapshot_date={snapshot_date}"
    bronze_dir.mkdir(parents=True, exist_ok=True)

    for file_path in files:
        frame = read_dataframe(file_path, dataset_cfg)
        frame.columns = [normalize_column(col) for col in frame.columns]
        frame["_dataset_name"] = dataset_name
        frame["_source_file"] = str(file_path.relative_to(PROJECT_ROOT))
        frame["_snapshot_date"] = snapshot_date
        frame["_ingested_at"] = datetime.utcnow().isoformat()
        frame = maybe_add_h3_columns(frame)

        output_name = f"{file_path.stem.replace('.', '_')}.parquet"
        output_path = bronze_dir / output_name
        frame.to_parquet(output_path, index=False)
        written += len(frame)
        print(f"[bronze] {dataset_name}: {file_path.name} -> {output_path.relative_to(PROJECT_ROOT)} ({len(frame)} rows)")

    return dataset_name, written


def main() -> None:
    args = parse_args()
    manifest_path = Path(args.manifest)
    manifest = load_manifest(manifest_path)

    totals: list[tuple[str, int]] = []
    for dataset_name, dataset_cfg in manifest.get("datasets", {}).items():
        totals.append(ingest_dataset(dataset_name, dataset_cfg, args.snapshot_date))

    print("\nBronze ingestion summary")
    for dataset_name, row_count in totals:
        print(f"- {dataset_name}: {row_count} rows written")


if __name__ == "__main__":
    main()
