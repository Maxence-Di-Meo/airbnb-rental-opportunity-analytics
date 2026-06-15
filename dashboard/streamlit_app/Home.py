from __future__ import annotations

import os

import pandas as pd
import plotly.express as px
import sqlalchemy as sa
import streamlit as st


st.set_page_config(page_title="Rural Tourism Invest France", layout="wide")


def postgres_engine() -> sa.Engine:
    user = os.getenv("POSTGRES_USER", "airbnb")
    password = os.getenv("POSTGRES_PASSWORD", "airbnb")
    host = os.getenv("POSTGRES_HOST", "localhost")
    port = os.getenv("POSTGRES_PORT", "5432")
    database = os.getenv("POSTGRES_DB", "airbnb_invest")
    return sa.create_engine(f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{database}")


@st.cache_data(ttl=300)
def load_zone_scores() -> pd.DataFrame:
    query = """
        select
            zone_id,
            zone_label,
            real_estate_month_key,
            nom_departement,
            nom_region,
            transaction_count,
            median_price_m2_bati,
            benchmark_entry_ticket_est,
            tourism_poi_count,
            nature_score,
            access_score,
            stability_score,
            seasonality_intensity,
            competition_proxy,
            tourism_potential_proxy,
            score_prudent,
            score_rendement,
            score_nature_premium,
            score_petit_budget
        from analytics.location_tourism_score_latest
        order by score_rendement desc nulls last
    """
    with postgres_engine().connect() as connection:
        return pd.read_sql(query, connection)


st.title("Rural Tourism Invest France")
st.caption("Scoring de communes rurales et touristiques a partir de DVF, attractivite, accessibilite et intensite touristique")

try:
    df = load_zone_scores()
except Exception as exc:
    st.error("La table analytics.location_tourism_score_latest est indisponible.")
    st.code(str(exc))
    st.info(
        "Charge d'abord les datasets touristiques et DVF dans data/external/, puis execute ingestion, chargement PostgreSQL et dbt."
    )
    st.stop()

if df.empty:
    st.warning("Aucune commune scoree pour le moment.")
    st.stop()

profile_map = {
    "Prudent": "score_prudent",
    "Rendement": "score_rendement",
    "Nature premium": "score_nature_premium",
    "Petit budget": "score_petit_budget",
}

with st.sidebar:
    selected_profile = st.selectbox("Profil investisseur", list(profile_map.keys()), index=1)
    min_transactions = st.slider(
        "Min transactions DVF",
        min_value=0,
        max_value=int(df["transaction_count"].fillna(0).max()),
        value=0,
    )
    min_tourism_poi = st.slider(
        "Min POI touristiques",
        min_value=0,
        max_value=int(df["tourism_poi_count"].fillna(0).max()),
        value=0,
    )
    top_n = st.slider("Top communes affichees", min_value=5, max_value=min(50, len(df)), value=min(15, len(df)))

score_column = profile_map[selected_profile]

filtered = df[
    (df["transaction_count"].fillna(0) >= min_transactions) &
    (df["tourism_poi_count"].fillna(0) >= min_tourism_poi)
].copy()
filtered = filtered.sort_values(score_column, ascending=False).head(top_n)

metric_1, metric_2, metric_3, metric_4 = st.columns(4)
metric_1.metric("Communes visibles", f"{len(filtered)}")
metric_2.metric(
    "Ticket d'entree median",
    f"{filtered['benchmark_entry_ticket_est'].median():.0f} EUR" if filtered["benchmark_entry_ticket_est"].notna().any() else "n/a",
)
metric_3.metric(
    "Potentiel touristique median",
    f"{filtered['tourism_potential_proxy'].median():.1f}" if filtered["tourism_potential_proxy"].notna().any() else "n/a",
)
metric_4.metric(
    "Access score median",
    f"{filtered['access_score'].median():.2f}" if filtered["access_score"].notna().any() else "n/a",
)

ranking_chart = px.bar(
    filtered,
    x="zone_label",
    y=score_column,
    color="tourism_potential_proxy",
    color_continuous_scale="YlGnBu",
    title=f"Top communes - profil {selected_profile.lower()}",
    labels={score_column: "Score", "zone_label": "Commune", "tourism_potential_proxy": "Potentiel touristique"},
)
ranking_chart.update_layout(xaxis_tickangle=-30)

scatter = px.scatter(
    filtered,
    x="benchmark_entry_ticket_est",
    y="tourism_potential_proxy",
    size="tourism_poi_count",
    hover_name="zone_label",
    color=score_column,
    color_continuous_scale="Turbo",
    title="Potentiel touristique vs ticket d'entree benchmark (60 m2)",
    labels={
        "benchmark_entry_ticket_est": "Ticket d'entree benchmark",
        "tourism_potential_proxy": "Potentiel touristique",
        "tourism_poi_count": "POI touristiques",
    },
)

left, right = st.columns(2)
left.plotly_chart(ranking_chart, use_container_width=True)
right.plotly_chart(scatter, use_container_width=True)

st.subheader("Classement detaille")
display_columns = [
    "zone_label",
    "nom_departement",
    "nom_region",
    score_column,
    "benchmark_entry_ticket_est",
    "tourism_potential_proxy",
    "nature_score",
    "access_score",
    "stability_score",
    "seasonality_intensity",
    "competition_proxy",
    "transaction_count",
]
st.dataframe(
    filtered[display_columns].rename(
        columns={
            score_column: "score",
            "zone_label": "commune",
            "nom_departement": "departement",
            "nom_region": "region",
            "benchmark_entry_ticket_est": "ticket_entree_benchmark",
            "tourism_potential_proxy": "potentiel_touristique",
            "nature_score": "nature",
            "access_score": "accessibilite",
            "stability_score": "stabilite",
            "seasonality_intensity": "intensite_saisonniere",
            "competition_proxy": "concurrence",
            "transaction_count": "transactions_dvf",
        }
    ),
    use_container_width=True,
)
