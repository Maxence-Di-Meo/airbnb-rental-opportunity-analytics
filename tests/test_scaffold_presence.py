from pathlib import Path


def test_expected_project_files_exist() -> None:
    root = Path(__file__).resolve().parents[1]
    expected = [
        root / "docker-compose.yml",
        root / "dags" / "tourism_rental_potential_pipeline.py",
        root / "dbt" / "dbt_project.yml",
        root / "dashboard" / "streamlit_app" / "Home.py",
        root / "config" / "source_manifest.yml",
    ]
    for path in expected:
        assert path.exists(), f"Missing scaffold file: {path}"
