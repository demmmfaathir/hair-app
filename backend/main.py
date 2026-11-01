import io
import json
import os
import time
from pathlib import Path

os.environ["USE_TF"] = "0"  # biar transformers pakai torch, bukan TensorFlow

import numpy as np
import tensorflow as tf
import torch
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
from transformers import CLIPModel, CLIPProcessor

from rules import DISCLAIMER, LABEL_ID, get_recommendations

MODEL_DIR = Path(__file__).parent / "model"
IMG = (224, 224)
THRESH = 0.60       # di bawah ini dianggap CNN kurang yakin
GATE_THRESH = 0.5   # naikkan kalau yang bukan rambut masih lolos, turunkan kalau foto rambut asli ditolak
REQUIRE_TOP_POS = True  # lolos hanya kalau prompt paling cocok adalah prompt rambut
GROUP_THRESH = 0.30     # skor "banyak orang" di atas ini ditolak (turunkan kalau foto grup masih lolos,
                        # naikkan kalau foto satu orang malah ditolak)

# ---------- CNN ----------
model = tf.keras.models.load_model(MODEL_DIR / "hair_EfficientNetB0.keras")
with open(MODEL_DIR / "class_names.json", encoding="utf-8") as f:
    class_names = json.load(f)

# ---------- CLIP gate (cek foto rambut atau bukan) ----------
clip = CLIPModel.from_pretrained("openai/clip-vit-base-patch32").eval()
clip_proc = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")

POS = [
    "a close-up photo of a person's hair",
    "a photo of a person's hairstyle with the hair clearly visible",
    "a photo of a person with long or medium-length hair",
    "a photo of a person with curly, wavy or straight hair",
    "a portrait photo of a person with visible hair",
    "a photo of a person with a mohawk hairstyle",
    "a photo of a person with short curly hair",
]
NEG = [
    # hewan
    "a photo of an animal",
    "a photo of a horse",
    "a photo of a dog",
    "a photo of a cat",
    "a photo of an animal with fur or a mane",
    # kepala/rambut tertutup
    "a photo of a person wearing a cap or a hat",
    "a photo of a person wearing a hijab or a headscarf",
    "a photo of a person wearing a helmet",
    "a photo of a person whose hair is covered",
    # rambut terlalu pendek / botak
    "a photo of a person with a buzz cut or very short cropped hair",
    "a photo of a person with a shaved head",
    "a photo of a bald head",
    # bukan orang
    "a photo of an object",
    "a photo of food",
    "a photo of a building or landscape",
    "a screenshot, text or document",
    "a drawing or cartoon",
    "a photo of a vehicle",
    "a photo of a plant or flower",
    "a photo of a doll or a toy",
]
# banyak orang dalam satu foto (tidak bisa dianalisis)
GROUP = [
    "a group photo of several people",
    "a photo of two or more people together",
    "a photo of three people",
]
PROMPTS = POS + NEG + GROUP
GROUP_START = len(POS) + len(NEG)


def hair_gate(img: Image.Image):
    """Return (skor rambut, skor banyak orang, prompt paling cocok, apakah prompt itu prompt rambut)."""
    inp = clip_proc(text=PROMPTS, images=img, return_tensors="pt", padding=True)
    with torch.no_grad():
        p = clip(**inp).logits_per_image[0].softmax(0).numpy()
    score = float(p[: len(POS)].sum())
    group = float(p[GROUP_START:].sum())
    best_idx = int(np.argmax(p))
    return score, group, PROMPTS[best_idx], best_idx < len(POS)


def image_quality(img: Image.Image):
    """Perkiraan kasar kualitas foto (heuristik, bukan ukuran ilmiah)."""
    g = np.asarray(img.convert("L").resize((256, 256)), dtype="float32")
    brightness = float(g.mean())
    lap = (
        4 * g[1:-1, 1:-1]
        - g[:-2, 1:-1]
        - g[2:, 1:-1]
        - g[1:-1, :-2]
        - g[1:-1, 2:]
    )
    sharp = float(lap.var())

    if brightness < 60:
        lighting = "Terlalu gelap"
    elif brightness > 200:
        lighting = "Terlalu terang"
    else:
        lighting = "Cukup"

    focus = "Tajam" if sharp >= 40 else "Kurang tajam"
    return lighting, focus


# ---------- API ----------
app = FastAPI(title="Hair Classifier API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # untuk development saja
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"status": "ok", "classes": class_names}


@app.post("/predict")
async def predict(
    file: UploadFile = File(...),
    scalp: str = Form("Normal"),
    condition: str = Form("Normal"),
    complaints: str = Form(""),  # dipisah koma, mis. "Frizz,Ketombe"
):
    if not (file.content_type or "").startswith("image/"):
        raise HTTPException(status_code=400, detail="File harus berupa gambar.")

    data = await file.read()
    try:
        img = Image.open(io.BytesIO(data)).convert("RGB")
    except Exception:
        raise HTTPException(status_code=400, detail="Gambar tidak bisa dibaca.")

    # 1) gate: tolak kalau bukan foto rambut yang jelas, atau berisi banyak orang
    g, grp, best, top_is_pos = hair_gate(img)
    print(
        f"[gate] score={g:.3f} | group={grp:.3f} | top_is_hair={top_is_pos} | paling cocok: {best}"
    )
    if grp >= GROUP_THRESH:
        raise HTTPException(
            status_code=422,
            detail=(
                "❌ Foto berisi lebih dari satu orang, jadi tidak bisa dianalisis. "
                "Satu foto hanya boleh berisi satu orang supaya rambut yang dinilai jelas. "
                "Coba unggah foto dengan satu orang saja."
            ),
        )
    if g < GATE_THRESH or (REQUIRE_TOP_POS and not top_is_pos):
        raise HTTPException(
            status_code=422,
            detail=(
                "❌ Bukan foto rambut yang jelas. Foto ini tidak terdeteksi sebagai satu orang dengan "
                f"rambut yang terlihat (skor {g:.0%}). Pastikan hanya ada satu orang di foto, rambut "
                "cukup panjang, terlihat jelas, dan tidak tertutup topi/hijab."
            ),
        )

    # 2) CNN: sama persis dengan prototype, resize saja, TANPA dibagi 255
    t0 = time.perf_counter()
    arr = np.array(img).astype("uint8")
    x = tf.image.resize(arr, IMG).numpy().astype("float32")[None]
    p = model.predict(x, verbose=0)[0]
    inference_ms = int((time.perf_counter() - t0) * 1000)

    order = np.argsort(p)[::-1]
    probs = [{"label": class_names[int(i)], "prob": float(p[int(i)])} for i in order]
    top = probs[0]
    low = top["prob"] < THRESH

    keluhan = sorted({c.strip() for c in complaints.split(",") if c.strip()})

    # kalau CNN kurang yakin, tidak ada rekomendasi
    recs = []
    if not low:
        facts = {"t": top["label"], "s": scalp, "c": condition, "k": set(keluhan)}
        recs = get_recommendations(facts)

    lighting, focus = image_quality(img)

    return {
        "label": top["label"],
        "label_id": LABEL_ID.get(top["label"], top["label"]),
        "confidence": top["prob"],
        "low_confidence": low,
        "gate_score": g,
        "probs": probs,
        "inputs": {"scalp": scalp, "condition": condition, "complaints": keluhan},
        "recommendations": recs,
        "disclaimer": DISCLAIMER,
        "telemetry": {
            "width": img.width,
            "height": img.height,
            "inference_ms": inference_ms,
            "lighting": lighting,
            "focus": focus,
        },
    }