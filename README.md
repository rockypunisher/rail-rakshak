# RAIL RAKSHAK: Dynamic Forecast of Expected Time of Arrival (ETA) for Coaching Trains
### Intelligent Railway Safety, Live Tracking & Operations Platform
### Ministry of Railways | SIH 2026 Problem Statement 26028

RAIL RAKSHAK is a production-style railway operations, passenger safety, and arrival forecasting platform. It replaces static timetable extrapolation with a **Hybrid Physics-Informed Kinematics + Statistical Residual Engine**, coupled with a **Where Is My Train**-style live tracking interface.

---

## 1. Quickstart & VS Code Setup

The platform is designed to run locally on Windows with zero Docker, zero Node/npm, and zero runtime CDNs:

```bash
# 1. Clone or navigate to the workspace
cd "C:\Users\A C E R\.gemini\antigravity\scratch\rail-dynamic-eta"

# 2. (Optional) Create and activate virtual environment
python -m venv venv
.\venv\Scripts\Activate.ps1

# 3. Install minimal dependencies (only fastapi, uvicorn, pydantic, pytest)
pip install -r requirements.txt

# 4. Launch the application
python run.py
```

The launcher will automatically initialize SQLite WAL tables, run initial holdout evaluation if needed, start Uvicorn on `http://127.0.0.1:8000`, and open your default browser.

To run contract tests:
```bash
pytest -v tests/test_api.py
```

---

## 2. System Architecture

```mermaid
flowchart TD
    subgraph Data Layer ["SQLite 3 (WAL Mode - Zero Dependencies)"]
        D1[(stations)]
        D2[(routes & route_stations)]
        D3[(trains)]
        D4[(history: 120-Day Synthetic Delays)]
        D5[(disruptions: TSR, Fog, Freight, Platform)]
    end

    subgraph Forecast Engine ["backend/engine.py (Pure Python)"]
        E1[Physics Kinematics: Speed limits, TSR caps, Fog cap]
        E2[Statistical Residuals: Train x Checkpoint x Season]
        E3[Online Bias Correction: Alpha = 0.2 Exponential Weighting]
        E4[Dynamic Slack Recovery: 15-23m near Terminals]
        E5[Split-Conformal 90% Uncertainty Interval]
        E6[Explainable AI Attribution: Fog, TSR, Freight, Slack]
    end

    subgraph Simulation & API ["FastAPI + asyncio (backend/simulator.py & routers.py)"]
        S1[Simulation Clock: 10:45 AM Start, 1x/5x/15x]
        S2[Kinematic Train Advancement & Station Halts]
        S3[Server-Sent Events: GET /api/v1/stream 1s feed]
        S4[REST Routers & OpenAPI Docs at /docs]
    end

    subgraph Frontend ["static/ (Vanilla JS ES Modules + Handwritten CSS)"]
        F1[Tab 1: Live Tracker - Where Is My Train Timeline & SVG Map]
        F2[Tab 2: Search & Timetable - Between Stations Enquiry]
        F3[Tab 3: Station Display Board - Amber Bilingual PIS LED]
        F4[Tab 4: Section Controller - COA Matrix & Sidelining Button]
        F5[Tab 5: Accuracy Benchmark - Holdout Test Metrics]
        F6[Laptop Top Bar: Clean Train ETA Dashboard, Live Status & Sim Controls]
        F7[Active Corridor Disruptions in Section Controller & Live Tracker]
    end

    Data Layer --> Forecast Engine
    Forecast Engine --> Simulation & API
    Simulation & API -->|SSE & REST| Frontend
    Frontend -->|Disruption Toggles & Dispatch| Simulation & API
```

---

## 3. Data Dictionary

- `stations`: `(code TEXT PK, name TEXT, zone TEXT, lat REAL, lon REAL, platforms INT)`
- `routes`: `(id INT PK, route_code TEXT, name TEXT, origin_code TEXT, dest_code TEXT, total_km REAL)`
- `route_stations`: `(id INT PK, route_id INT, seq INT, station_code TEXT, km REAL, sched_arr TEXT, sched_dep TEXT, halt_min INT, sectional_speed REAL)`
- `trains`: `(no TEXT PK, name TEXT, type TEXT, priority INT, max_speed REAL, route_id INT)`
- `history`: `(id INT PK, train_no TEXT, station_code TEXT, date TEXT, sched TEXT, actual_delay REAL, source_label TEXT)`
- `disruptions`: `(id INT PK, type TEXT, km_from REAL, km_to REAL, severity TEXT, minutes REAL, active INT, description TEXT)`

---

## 4. API Endpoints

All endpoints are self-documented at `http://127.0.0.1:8000/docs`:

### Live Operations & Tracking
- `GET /health`: Operational health check.
- `GET /api/v1/trains/search?q={query}`: Autocomplete search for trains by number or name.
- `GET /api/v1/trains/{no}/live`: Complete "Where Is My Train" telemetry payload (speed, delay, distance, ordered checkpoints, AI ETA, NTES, actual, 90% conformal window, XAI delay attribution).
- `GET /api/v1/between?from={st}&to={st}`: Search scheduled trains between two stations.
- `GET /api/v1/stream`: Real-time Server-Sent Events (SSE) feed updating train positions, clock, and disruption states every 1 second.

### Control Room & Disruption Management
- `GET /api/v1/disruptions`: List all operational disruptions.
- `POST /api/v1/disruptions`: Toggle disruptions (Fog, TSR, Freight Block, Platform Congestion).
- `POST /api/v1/control-room/dispatch`: Authorize sidelining of freight train BCN-9844 to Loop Line 3 to clear precedence for passenger expresses.
- `GET /api/v1/sim` & `POST /api/v1/sim`: Simulation controls (play, pause, reset, speed multiplier 1x/5x/15x).

### Model Accuracy & Benchmark
- `GET /api/v1/model/metrics`: Measured accuracy statistics on holdout test set from `backend/metrics.json`.
- `GET /api/v1/data/coverage`: Exact open-data coverage counts across Indian Railways (8,990 stations, 5,210 trains, 417,038 schedules, and real vs synthetic delay observations).

### Backward-Compatible Endpoints (Preserved from Original Prototype)
- `GET /api/v1/eta/train/{no}?station={code}`: Single-checkpoint dynamic ETA prediction.
- `GET /api/v1/station/{code}/display-board`: Bilingual English/Hindi Passenger Information System (PIS) board.
- `GET /api/v1/control-room/corridor-matrix`: Section Controller occupancy matrix with 3-aspect block signal states and bottleneck warnings.

---

## 5. Nationwide Open Data Pipeline & Honest Provenance

The platform was expanded using official open datasets with strict provenance tracking recorded in [SOURCES.md](file:///C:/Users/A%20C%20E%20R/.gemini/antigravity/scratch/rail-dynamic-eta/backend/data/SOURCES.md):

1. **Timetable & Geographic Data (REAL)**:
   - **8,990 Stations**: Ingested from DataMeet (`stations.json`, CC0 1.0 Public Domain) with precise GPS coordinates, station codes, English names, state, and railway zones.
   - **417,038 Scheduled Checkpoints**: Ingested from DataMeet (`schedules.json`, CC0 1.0 Public Domain) covering sequential arrival times, departure times, day offsets, and calculated cumulative route distances.
   - **5,210 Passenger Trains**: Spanning all 17 railway zones (Northern NR, Western WR, Southern SR, Eastern ER, South Central SCR, etc.), including premier expresses like Rajdhani, Shatabdi, Vande Bharat, Duronto, and long-distance trains (e.g. 12615/12616 Grand Trunk Express, 16031/16032 Andaman Express).
2. **Operational Delays (SYNTHETIC)**:
   - For trains without direct satellite RTIS feeds, 69,180 delay observations were generated using deterministic, fixed-seed rules reflecting real-world railway physics: Indo-Gangetic winter radiation fog (Dec–Feb speed reductions), train priority precedence, sectional peak headway congestion, and terminal recovery slack absorption.
   - Every response and UI card explicitly displays the provenance badge: **"Real timetable + simulated delays"**.
3. **No Scraping**: No automated scraping was performed against IRCTC, NTES, or any portal with Terms of Service prohibiting scraping.

---

## 6. Honest Limitations

1. **Simulated vs Real Telemetry**: Timetables, stations, stopping sequences, and geographic coordinates are **100% REAL open data**. The delay numbers are **calibrated synthetic simulations** based on documented Indian Railways operating conditions, not live GPS RTIS satellite streams.
2. **Production Adaptor Interface**: In a live Indian Railways deployment, RTIS (Real-Time Train Information System GPS via ISRO GSAT) and COA (Control Office Application) feeds would plug into `backend/simulator.py` via asynchronous messaging adaptors (Kafka / RabbitMQ) without changing the REST API contracts or forecast engine.
3. **Pure Python Computation**: To ensure complete offline portability on Windows without requiring C++ build tools, NumPy, PyTorch, or Scikit-learn, statistical distributions and conformal quantiles are computed in standard library Python.

---

## 7. Verification Summary & Honest Provenance Audit

- **REAL**: 8,990 stations, 5,210 passenger trains, and 417,038 scheduled stops across all 17 railway zones downloaded from DataMeet (CC0 1.0 Public Domain) and data.gov.in.
- **REAL**: Dynamic hybrid physics kinematic calculations, sectional speed limits, TSR caps, 3-aspect block signals, time-based holdout evaluation, and empirical 90% conformal coverage windows.
- **SYNTHETIC**: 69,180 delay history observations and real-time live telemetry feeds, calibrated with fixed-seed deterministic rules (winter fog, terminal slack, priority precedence) as labeled in all API `meta` tags.
- **FAILED (External Downloads)**: RSTGCN delay CSV (WinError 10054 remote host drop / SSL certificate restriction) and raw DataMeet trains.json (SSL cert chain); safely substituted by DataMeet schedules-derived train catalog and documented in `SOURCES.md` and `README.txt`.
- **VERIFIED**: All 13 test suites (`tests/test_api.py`) and all 11 core API endpoints verified 100% operational on local Windows environment with zero CDNs or npm dependencies.
