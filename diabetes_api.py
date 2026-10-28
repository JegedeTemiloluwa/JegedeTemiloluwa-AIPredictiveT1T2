from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel
import pandas as pd
import numpy as np
import joblib
import os
import json

# Set up the FastAPI app with a short description
app = FastAPI(
    title="DiaGuard AI – Diabetes Prediction API",
    description="Stacking Ensemble model for diabetes type and stage classification",
    version="1.0.0",
)

# Allow requests from any origin so the web dashboard and mobile app can connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Path to the saved model files
MODEL_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "models")

# These will be loaded when the server starts
type_model = None
stage_model = None
label_encoder_type = None
label_encoder_stage = None
feature_names = None
scaler = None
medians = None
metrics = None


# Input data structure – matches the 10 features used during training
class PatientData(BaseModel):
    Glucose: float
    BloodPressure: float
    Insulin: float
    BMI: float
    Age: float
    HbA1c: float
    Hypertension: int
    HeartDisease: int
    Smoking: int
    Gender: int


@app.on_event("startup")
def load_models():
    """Load all model files and supporting assets when the server starts."""
    global type_model, stage_model, label_encoder_type, label_encoder_stage
    global feature_names, scaler, medians, metrics

    try:
        type_model = joblib.load(os.path.join(MODEL_DIR, "type_model.pkl"))
        stage_model = joblib.load(os.path.join(MODEL_DIR, "stage_model.pkl"))
        label_encoder_type = joblib.load(os.path.join(MODEL_DIR, "label_encoder_type.pkl"))
        label_encoder_stage = joblib.load(os.path.join(MODEL_DIR, "label_encoder_stage.pkl"))
        feature_names = joblib.load(os.path.join(MODEL_DIR, "features.pkl"))
        scaler = joblib.load(os.path.join(MODEL_DIR, "scaler.pkl"))
        medians = joblib.load(os.path.join(MODEL_DIR, "medians.pkl"))

        with open(os.path.join(MODEL_DIR, "real_metrics.json"), "r") as f:
            metrics = json.load(f)

        print("Models loaded successfully.")
    except Exception as e:
        print(f"Error loading models: {str(e)}")


@app.get("/")
def home():
    """Serve the web dashboard (index.html)."""
    index_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "index.html")
    if os.path.exists(index_path):
        return FileResponse(index_path)
    return {"status": "running", "message": "index.html not found in project root"}


@app.get("/api/info")
def api_info():
    """Return basic model performance information – used by the mobile app health check."""
    if not metrics:
        return {"status": "Offline"}

    return {
        "title": "DiaGuard AI – Diabetes Prediction",
        "version": "1.0.0",
        "accuracy": {
            "type_f1": f"{metrics['Type']['test_f1_macro']:.2f}%",
            "stage_f1": f"{metrics['Stage']['test_f1_macro']:.2f}%",
            "overall": f"{metrics['Type']['test_accuracy']:.2f}%",
        },
        "note": "Evaluated on a held-out 20% test split with stratified cross-validation.",
        "status": "Operational",
    }


@app.post("/predict")
def predict(patient: PatientData):
    """
    Accept patient biomarker data and return a diabetes classification result.

    The model predicts:
    - Diagnosis: Healthy, At Risk, Type 1, or Type 2
    - Stage: severity level (Stage 1, 2, or 3)
    - Confidence scores for each class
    - A simple clinical recommendation based on the result
    """
    if not type_model:
        raise HTTPException(status_code=503, detail="Models are not loaded yet.")

    try:
        # Convert input to a DataFrame and select the correct feature order
        input_data = patient.dict()
        input_df = pd.DataFrame([input_data])[feature_names]

        # Fill any missing values using training-set medians
        input_df = input_df.fillna(medians)

        # Scale the input using the same scaler fitted during training
        X_scaled = scaler.transform(input_df)

        # Run both classifiers
        type_index = type_model.predict(X_scaled)[0]
        stage_index = stage_model.predict(X_scaled)[0]

        # Get class probabilities for the type prediction
        type_proba = type_model.predict_proba(X_scaled)[0]
        confidence = {
            str(cls): float(prob * 100)
            for cls, prob in zip(label_encoder_type.classes_, type_proba)
        }

        # Decode the predicted labels
        diagnosis = str(label_encoder_type.inverse_transform([type_index])[0])
        stage = str(label_encoder_stage.inverse_transform([stage_index])[0])

        # Build a recommendation based on the result
        recommendation = "Maintain regular check-ups and follow a balanced lifestyle."
        clinical_note = None

        if diagnosis == "Type 1":
            recommendation = "Please consult an endocrinologist as soon as possible for insulin therapy assessment."
        elif diagnosis == "Type 2":
            recommendation = "Speak with your doctor about glucose management, dietary changes, and medication options."
            if confidence.get(diagnosis, 100) < 60:
                clinical_note = (
                    "The model confidence for this result is below 60%. "
                    "Please seek professional medical confirmation."
                )
        elif diagnosis == "At Risk":
            recommendation = "Monitor your glucose and HbA1c regularly, and increase physical activity."

        # Adjust recommendation based on severity stage
        if stage == "Stage 3":
            recommendation += " Severity is high – please seek immediate medical attention."
        elif stage == "Stage 2":
            recommendation += " Follow up with your doctor within the next 48 hours."
        elif stage == "Stage 1":
            recommendation += " Early detection – discuss preventive steps with your physician."

        return {
            "diagnosis": diagnosis,
            "stage": stage,
            "confidence": confidence,
            "recommendation": recommendation,
            "disclaimer": clinical_note,
            "timestamp": pd.Timestamp.now().isoformat(),
            "model_version": "1.0.0",
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
