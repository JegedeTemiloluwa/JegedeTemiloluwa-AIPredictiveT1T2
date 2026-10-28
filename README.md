# DiaGuard AI — Diabetes Early Detection System

A machine learning system for early detection and classification of diabetes, developed as a final year project at Afe Babalola University, Nigeria.

**Author:** Jegede Temiloluwa Racheal  
**Matric No:** 22/SCI01/087  
**Department:** Computer Science, Faculty of Sciences  
**Degree:** B.Sc. Computer Science, June 2026

---

## What This Project Does

DiaGuard AI accepts ten clinical biomarkers from a patient and predicts:

1. **Diabetes Type** — whether the patient is Healthy, At Risk, has Type 1, or Type 2 diabetes  
2. **Disease Stage** — the severity level (Stage 1, Stage 2, or Stage 3)

The system is made up of two parts:

- A **FastAPI backend** that runs the machine learning model and exposes a `/predict` endpoint
- A **Flutter mobile app** and a **web dashboard** that let users enter their health data and receive a result

The web dashboard is hosted live at:  
👉 **https://jegedetemiloluwa-aipredictivet1t2.onrender.com**

---

## Input Features

The model uses the following ten clinical measurements:

| Feature | Description |
|---|---|
| Glucose | Blood glucose level (mg/dL) |
| Blood Pressure | Diastolic blood pressure (mmHg) |
| Insulin | Serum insulin level (µU/mL) |
| BMI | Body Mass Index (kg/m²) |
| Age | Patient age in years |
| HbA1c | Glycated haemoglobin (%) |
| Hypertension | Whether the patient has hypertension (0 or 1) |
| Heart Disease | Whether the patient has heart disease (0 or 1) |
| Smoking History | Encoded smoking category |
| Gender | Male = 1, Female = 0 |

---

## Model Architecture

The prediction model is a **Stacking Ensemble Classifier** that combines three base learners:

- Logistic Regression
- XGBoost
- Random Forest

A second logistic regression is used as the meta-learner that takes the outputs of all three base models and produces the final prediction.

Training was done with **5-fold stratified cross-validation** with in-fold class balancing, ensuring no data leakage between training and validation sets.

### Performance on Held-Out Test Set (80/20 split)

| Metric | Diabetes Type | Disease Stage |
|---|---|---|
| Accuracy | 88.54% | 87.89% |
| Macro F1 Score | 88.02% | 88.34% |
| Macro Precision | 88.21% | 88.45% |
| Macro Recall | 87.95% | 88.12% |

---

## Project Structure

```
├── diabetes_api.py           # FastAPI backend – handles prediction requests
├── hybrid_train_final.py     # Model training script
├── balanced_master_dataset.csv  # Dataset used for training
├── index.html                # Web dashboard (same design as the mobile app)
├── requirements.txt          # Python dependencies
├── render.yaml               # Render deployment configuration
├── Procfile                  # Process file for deployment
├── models/
│   ├── type_model.pkl        # Trained diabetes type classifier
│   ├── stage_model.pkl       # Trained disease stage classifier
│   ├── label_encoder_type.pkl
│   ├── label_encoder_stage.pkl
│   ├── scaler.pkl            # StandardScaler fitted on training data
│   ├── medians.pkl           # Training medians for missing value imputation
│   ├── features.pkl          # Ordered list of feature names
│   └── real_metrics.json     # Full evaluation metrics from training
├── mobile_app/               # Flutter mobile application
│   └── lib/
│       ├── main.dart
│       ├── screens/          # Login, Signup, Dashboard, Input, Result screens
│       └── services/         # API, Auth, Storage services
└── type_detailed_report.txt  # Full classification report for Type prediction
└── stage_detailed_report.txt # Full classification report for Stage prediction
```

---

## How to Run Locally

### 1. Clone the repository

```bash
git clone https://github.com/JegedeTemiloluwa/JegedeTemiloluwa-AIPredictiveT1T2.git
cd JegedeTemiloluwa-AIPredictiveT1T2
```

### 2. Install Python dependencies

```bash
pip install -r requirements.txt
```

### 3. Start the API server

```bash
uvicorn diabetes_api:app --host 0.0.0.0 --port 8000
```

Then open your browser and go to **http://localhost:8000** to use the web dashboard.

### 4. Run the mobile app (optional)

Make sure Flutter is installed, then:

```bash
cd mobile_app
flutter pub get
flutter run
```

The app will connect to the live Render API by default. To use your local server instead, update `_baseUrl` in `mobile_app/lib/services/api_service.dart` to `http://10.0.2.2:8000` (for Android emulator) or `http://localhost:8000` (for web).

---

## How to Retrain the Model

If you want to retrain the model on new data, place your dataset at the root as `balanced_master_dataset.csv` with the same column structure, then run:

```bash
python hybrid_train_final.py
```

The script will save all updated model files to the `/models` folder automatically.

---

## Deployment

The API is deployed on **Render** (free tier) using the included `render.yaml` configuration. Any push to the `main` branch on GitHub will trigger an automatic redeployment.

API health check: https://jegedetemiloluwa-aipredictivet1t2.onrender.com/api/info

---

## Technologies Used

| Layer | Technology |
|---|---|
| Machine Learning | scikit-learn, XGBoost |
| API Backend | FastAPI, Uvicorn |
| Mobile App | Flutter (Dart) |
| Web Dashboard | HTML, CSS, JavaScript |
| Deployment | Render (free tier) |
| Dataset | Custom balanced dataset (clinical biomarkers) |

---

## Disclaimer

This system is developed for academic research purposes only. It is not a substitute for professional medical diagnosis. All predictions should be reviewed by a qualified healthcare professional before any clinical decision is made.
