from __future__ import annotations

import argparse
from pathlib import Path

import pandas as pd
import sqlalchemy as sa
import yaml

from src.utils.settings import PROJECT_ROOT, postgres_url


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Load bronze parquet datasets into PostgreSQL raw schema.")
    parser.add_argument("--manifest", required=True, help="Path to YAML manifest describing local source files.")
    parser.add_argument(
        "--if-exists",
        default="replace",
        choices=["replace", "append"],
        help="Behavior when writing raw tables.",
    )
    return parser.parse_args()


def load_manifest(manifest_path: Path) -> dict:
    with manifest_path.open("r", encoding="utf-8") as stream:
        return yaml.safe_load(stream)


def bronze_files_for_dataset(dataset_name: str) -> list[Path]:
    dataset_root = PROJECT_ROOT / "data" / "lake" / "bronze" / dataset_name
    return sorted(dataset_root.glob("snapshot_date=*/*.parquet"))


def empty_frame_for_dataset(dataset_cfg: dict) -> pd.DataFrame:
    columns = dataset_cfg.get("expected_columns", [])
    metadata_columns = ["_dataset_name", "_source_file", "_snapshot_date", "_ingested_at"]
    return pd.DataFrame(columns=[*columns, *metadata_columns])


def main() -> None:
    args = parse_args()
    manifest = load_manifest(Path(args.manifest))
    engine = sa.create_engine(postgres_url())

    with engine.begin() as connection:
        connection.execute(sa.text("CREATE SCHEMA IF NOT EXISTS raw"))

    for dataset_name, dataset_cfg in manifest.get("datasets", {}).items():
        bronze_files = bronze_files_for_dataset(dataset_name)
        if not bronze_files:
            if dataset_cfg.get("required_for_mvp", False):
                raise FileNotFoundError(f"No bronze parquet files found for required dataset: {dataset_name}")
            empty_frame_for_dataset(dataset_cfg).to_sql(
                name=dataset_cfg["table_name"],
                con=engine,
                schema="raw",
                if_exists=args.if_exists,
                index=False,
            )
            print(f"[raw] raw.{dataset_cfg['table_name']} created as empty table (optional dataset not provided)")
            continue

        frames = [pd.read_parquet(path) for path in bronze_files]
        combined = pd.concat(frames, ignore_index=True)
        table_name = dataset_cfg["table_name"]
        combined.to_sql(
            name=table_name,
            con=engine,
            schema="raw",
            if_exists=args.if_exists,
            index=False,
            chunksize=5000,
            method="multi",
        )
        print(f"[raw] raw.{table_name} <- {len(combined)} rows from {len(bronze_files)} parquet file(s)")


if __name__ == "__main__":
    main()
