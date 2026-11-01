import sys
import json
from pathlib import Path

import numpy as np
import tensorflow as tf
from PIL import Image

MODEL_DIR = Path(__file__).parent / "model"
model = tf.keras.models.load_model(MODEL_DIR / "hair_EfficientNetB0.keras")
with open(MODEL_DIR / "class_names.json", encoding="utf-8") as f:
    class_names = json.load(f)

test_dir = Path(sys.argv[1])
n = len(class_names)
cm = np.zeros((n, n), dtype=int)  # baris = label asli, kolom = prediksi

for ci, cname in enumerate(class_names):
    for f in (test_dir / cname).glob("*"):
        if f.suffix.lower() not in (".jpg", ".jpeg", ".png", ".webp"):
            continue
        img = Image.open(f).convert("RGB")
        x = tf.image.resize(np.array(img).astype("uint8"), (224, 224)).numpy().astype("float32")[None]
        cm[ci, int(np.argmax(model.predict(x, verbose=0)[0]))] += 1

print("Urutan kelas:", class_names)
print("Confusion matrix (baris=asli, kolom=prediksi):")
print(cm)
print("Akurasi:", round(cm.trace() / cm.sum(), 4))