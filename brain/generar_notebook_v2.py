"""
Genera motor_predictivo_v2_colab.ipynb con traducción EN→ES integrada.
Ejecutar: python generar_notebook.py
"""
import json

def cell_md(source, id_):
    return {"cell_type":"markdown","metadata":{"id":id_},"source":[source],"id":id_}

def cell_code(source, id_):
    return {"cell_type":"code","execution_count":None,"metadata":{"id":id_},"outputs":[],"source":[source],"id":id_}

BANNER = ('<div style="background:#1C3257;color:#F7F3EB;padding:22px 26px;border-radius:10px;font-family:Calibri">'
          '<div style="color:#E08A6E;font-size:12px;font-weight:bold">MINERÍA DE DATOS · PROYECTO FINAL · UPCh 2026A</div>'
          '<div style="font-size:26px;font-weight:bold">Motor Predictivo v2 — Traducción EN→ES + Fine-tuning BETO</div>'
          '<div style="font-style:italic;color:#C9D4E4">Dataset traducido al español → BETO en su idioma nativo → Predicción de rating real</div></div>')

S0_SETUP = """\
# Instalación
!pip install -q transformers sentencepiece sacremoses datasets scikit-learn tqdm pandas torch

import gc, json, os
import numpy as np
import pandas as pd
import torch
from torch import nn
from torch.utils.data import Dataset, DataLoader
from transformers import (BertTokenizerFast, BertModel,
                          MarianMTModel, MarianTokenizer,
                          get_linear_schedule_with_warmup)
from torch.optim import AdamW
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, r2_score
from tqdm.notebook import tqdm

DEVICE = 'cuda' if torch.cuda.is_available() else 'cpu'
print(f'✅ Dispositivo: {DEVICE}')
if torch.cuda.is_available():
    print(f'🎮 GPU: {torch.cuda.get_device_name(0)}')
    print(f'💾 VRAM total: {torch.cuda.get_device_properties(0).total_memory/1e9:.1f} GB')

def liberar_memoria():
    gc.collect()
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
    print('🧹 Memoria liberada.')
"""

S1_LOAD = """\
from google.colab import files
print('📂 Sube el archivo collegereview2021.csv ...')
uploaded = files.upload()

df = pd.read_csv('collegereview2021.csv')
df = df[['review','rating']].dropna()
df['rating'] = pd.to_numeric(df['rating'], errors='coerce')
df = df.dropna(subset=['rating'])
df = df[df['rating'].between(0,10)]

# Truncar a 120 palabras antes de traducir (Helsinki-NLP rinde mejor con textos cortos)
df['review_truncada'] = df['review'].astype(str).apply(lambda x: ' '.join(x.split()[:120]))

print(f'📊 Registros válidos: {len(df)}')
print(f'⭐ Rating promedio: {df["rating"].mean():.2f}')
print(f'\\nEjemplo de review (primeros 100 chars):')
print(df["review_truncada"].iloc[0][:100])
"""

S2_TRANSLATE = """\
# ─── Traducción EN → ES con Helsinki-NLP/opus-mt-en-es ─────────────────────
CACHE_FILE = 'reviews_traducidas.csv'

if os.path.exists(CACHE_FILE):
    print(f'✅ Caché encontrado: {CACHE_FILE}. Cargando sin re-traducir...')
    df_es = pd.read_csv(CACHE_FILE)
else:
    print('🔄 Cargando modelo de traducción Helsinki-NLP/opus-mt-en-es...')
    mt_tokenizer = MarianTokenizer.from_pretrained('Helsinki-NLP/opus-mt-en-es')
    mt_model     = MarianMTModel.from_pretrained('Helsinki-NLP/opus-mt-en-es').to(DEVICE)
    mt_model.eval()

    BATCH = 32
    textos = df['review_truncada'].tolist()
    traducciones = []

    print(f'🌐 Traduciendo {len(textos)} reseñas en lotes de {BATCH}...')
    pbar = tqdm(range(0, len(textos), BATCH), desc='Traduciendo', unit='batch')

    for i in pbar:
        lote = textos[i:i+BATCH]
        tokens = mt_tokenizer(lote, return_tensors='pt', padding=True,
                              truncation=True, max_length=256).to(DEVICE)
        with torch.no_grad():
            out = mt_model.generate(**tokens, max_new_tokens=200)
        traducciones.extend(mt_tokenizer.batch_decode(out, skip_special_tokens=True))
        pbar.set_postfix({'traducidos': min(i+BATCH, len(textos))})

    df_es = df[['rating']].copy()
    df_es['review_es'] = traducciones
    df_es['rating_norm'] = df_es['rating'] / 10.0
    df_es.to_csv(CACHE_FILE, index=False)
    print(f'\\n💾 Guardado caché: {CACHE_FILE}')

    # Descargar para no perderlo si Colab se reinicia
    files.download(CACHE_FILE)

    del mt_model, mt_tokenizer
    liberar_memoria()

print(f'\\n✅ Dataset en español listo: {len(df_es)} registros')
print(f'\\nEjemplo traducido:')
print(df_es['review_es'].iloc[0][:120])
"""

S3_SPLIT = """\
train_df, test_df = train_test_split(df_es, test_size=0.2, random_state=42)
print(f'📚 Entrenamiento: {len(train_df)} | 🧪 Prueba: {len(test_df)}')
print(f'\\nMuestra de texto en español:')
for i in range(2):
    print(f'  [{i+1}] Rating={train_df[\"rating\"].iloc[i]:.1f} | {train_df[\"review_es\"].iloc[i][:80]}...')
"""

S4_DATASET = """\
MODEL_NAME = 'dccuchile/bert-base-spanish-wwm-uncased'  # BETO — español nativo
MAX_LEN    = 256

print(f'🤖 Cargando tokenizer: {MODEL_NAME} ...')
tokenizer = BertTokenizerFast.from_pretrained(MODEL_NAME)
print('✅ Tokenizer listo')

# Ejemplo de tokenización en español
ejemplo = train_df['review_es'].iloc[0]
toks = tokenizer(ejemplo[:200], return_tensors='pt')
print(f'\\nTokens del ejemplo (primeros 10): {tokenizer.convert_ids_to_tokens(toks[\"input_ids\"][0][:10])}')

class ReviewDataset(Dataset):
    def __init__(self, textos, ratings):
        self.textos  = textos.tolist()
        self.ratings = ratings.tolist()

    def __len__(self):
        return len(self.textos)

    def __getitem__(self, idx):
        enc = tokenizer(self.textos[idx], truncation=True, max_length=MAX_LEN,
                        padding='max_length', return_tensors='pt')
        return {
            'input_ids':      enc['input_ids'].squeeze(),
            'attention_mask': enc['attention_mask'].squeeze(),
            'label':          torch.tensor(self.ratings[idx], dtype=torch.float)
        }

BATCH_SIZE = 16
train_ds = ReviewDataset(train_df['review_es'], train_df['rating_norm'])
test_ds  = ReviewDataset(test_df['review_es'],  test_df['rating_norm'])
train_dl = DataLoader(train_ds, batch_size=BATCH_SIZE, shuffle=True,  num_workers=2)
test_dl  = DataLoader(test_ds,  batch_size=BATCH_SIZE, num_workers=2)
print(f'\\n📦 Batches — Train: {len(train_dl)} | Test: {len(test_dl)}')
"""

S5_MODEL = """\
class BETORegressor(nn.Module):
    def __init__(self, dropout=0.3):
        super().__init__()
        self.bert = BertModel.from_pretrained(MODEL_NAME)
        h = self.bert.config.hidden_size
        self.regressor = nn.Sequential(
            nn.Dropout(dropout),
            nn.Linear(h, 128),
            nn.ReLU(),
            nn.Linear(128, 1),
            nn.Sigmoid()
        )

    def forward(self, input_ids, attention_mask):
        out    = self.bert(input_ids=input_ids, attention_mask=attention_mask)
        cls    = out.last_hidden_state[:, 0, :]  # vector [CLS]
        return self.regressor(cls).squeeze(-1)

modelo = BETORegressor().to(DEVICE)
params = sum(p.numel() for p in modelo.parameters())
print(f'✅ BETORegressor cargado')
print(f'   Parámetros totales : {params:,}')
print(f'   Hidden size (BETO) : {modelo.bert.config.hidden_size}')
print(f'   Dispositivo        : {DEVICE}')
"""

S6_TRAIN = """\
EPOCHS = 3
loss_fn   = nn.MSELoss()
optimizer = AdamW([
    {'params': modelo.bert.parameters(),      'lr': 2e-5},
    {'params': modelo.regressor.parameters(), 'lr': 1e-3}
])
total_steps = len(train_dl) * EPOCHS
scheduler   = get_linear_schedule_with_warmup(
    optimizer,
    num_warmup_steps=int(0.1 * total_steps),
    num_training_steps=total_steps
)

def epoch_train(modelo, dl):
    modelo.train()
    total_loss = 0
    pbar = tqdm(dl, desc='  🔧 Train', leave=False, unit='batch')
    for batch in pbar:
        ids  = batch['input_ids'].to(DEVICE)
        mask = batch['attention_mask'].to(DEVICE)
        y    = batch['label'].to(DEVICE)
        optimizer.zero_grad()
        pred = modelo(ids, mask)
        loss = loss_fn(pred, y)
        loss.backward()
        torch.nn.utils.clip_grad_norm_(modelo.parameters(), 1.0)
        optimizer.step(); scheduler.step()
        total_loss += loss.item()
        pbar.set_postfix({'loss': f'{loss.item():.4f}'})
    return total_loss / len(dl)

def epoch_eval(modelo, dl):
    modelo.eval()
    total_loss, preds_all, y_all = 0, [], []
    pbar = tqdm(dl, desc='  🧪 Eval ', leave=False, unit='batch')
    with torch.no_grad():
        for batch in pbar:
            ids  = batch['input_ids'].to(DEVICE)
            mask = batch['attention_mask'].to(DEVICE)
            y    = batch['label'].to(DEVICE)
            pred = modelo(ids, mask)
            total_loss += loss_fn(pred, y).item()
            preds_all.extend((pred.cpu().numpy() * 10).tolist())
            y_all.extend((y.cpu().numpy() * 10).tolist())
    mae = mean_absolute_error(y_all, preds_all)
    r2  = r2_score(y_all, preds_all)
    return total_loss / len(dl), mae, r2

print(f'🚀 Iniciando entrenamiento — {EPOCHS} épocas, {total_steps} steps totales')
print('='*65)
print(f'{'Época':<6} | {'Loss Train':<12} | {'Loss Val':<10} | {'MAE (0-10)':<12} | R²')
print('-'*65)

best_mae = float('inf')
for epoch in tqdm(range(1, EPOCHS+1), desc='📈 Épocas', unit='epoch'):
    loss_t            = epoch_train(modelo, train_dl)
    loss_v, mae, r2   = epoch_eval(modelo, test_dl)
    marca = ' ✅ MEJOR' if mae < best_mae else ''
    best_mae = min(best_mae, mae)
    print(f'{epoch:<6} | {loss_t:<12.4f} | {loss_v:<10.4f} | {mae:<12.4f} | {r2:.4f}{marca}')

print('='*65)
print(f'\\n🏆 Mejor MAE alcanzado: {best_mae:.4f} (escala 0-10)')
"""

S7_INFER = """\
def predecir_rating(texto: str) -> dict:
    '''Predice el rating (0-10) de un evento académico dado su descripción en ESPAÑOL.'''
    modelo.eval()
    enc = tokenizer(texto, truncation=True, max_length=MAX_LEN,
                    padding='max_length', return_tensors='pt')
    with torch.no_grad():
        rating_norm = modelo(
            enc['input_ids'].to(DEVICE),
            enc['attention_mask'].to(DEVICE)
        ).item()
    rating = round(rating_norm * 10, 2)
    return {
        'rating_predicho':                  rating,
        'sentimiento':                      'positivo' if rating >= 7 else ('neutral' if rating >= 4 else 'negativo'),
        'porcentaje_asistencia_estimado':   round(rating * 10, 1)
    }

# ── Pruebas en ESPAÑOL ──────────────────────────────────────────────────────
print('🔮 Pruebas de inferencia en Español:')
print('='*80)
casos = [
    'El taller de robótica fue increíble. Los profesores explicaron muy bien y el laboratorio estaba perfectamente equipado.',
    'Pésima experiencia. El salón estaba sucio, el profesor llegó tarde y el contenido era aburrido.',
    'Conferencia aceptable. Algunos temas fueron interesantes aunque la duración fue demasiado larga.',
]
for texto in casos:
    r = predecir_rating(texto)
    barra = '█' * int(r['rating_predicho']) + '░' * (10 - int(r['rating_predicho']))
    print(f'  Texto: {texto[:65]}...')
    print(f'  [{barra}] ⭐ {r[\"rating_predicho\"]}/10 — {r[\"sentimiento\"].upper()} — Asistencia estimada: {r[\"porcentaje_asistencia_estimado\"]}%')
    print()
"""

S8_SAVE = """\
RUTA = 'modelo_predictivo.pt'
torch.save({
    'model_state_dict': modelo.state_dict(),
    'model_name':       MODEL_NAME,
    'max_len':          MAX_LEN,
    'version':          '2.0.0',
    'idioma':           'es'
}, RUTA)
size_mb = os.path.getsize(RUTA) / (1024*1024)
print(f'💾 Modelo guardado: {RUTA} ({size_mb:.1f} MB)')
print('\\n📥 Descargando a tu computadora...')
files.download(RUTA)
print('\\n📋 PRÓXIMOS PASOS:')
print('  1. Guarda reviews_traducidas.csv (ya descargado) para no re-traducir')
print('  2. Sube modelo_predictivo.pt al EC2:')
print('     scp -i NiggaFlex.pem modelo_predictivo.pt ubuntu@<IP>:~/INTEGER09.../nlp_service/models_cache/')
print('  3. docker compose restart nlp')
print('  4. Prueba el endpoint: POST /api/ml/predict')
"""

cells = [
    cell_md(BANNER, "header"),
    cell_md("## Objetivo\n\nEste Notebook corrige la incompatibilidad de idioma de la v1. Primero **traduce** el dataset de inglés a español usando `Helsinki-NLP/opus-mt-en-es`, cachea las traducciones y luego realiza el fine-tuning de **BETO** con texto en su idioma nativo.\n\n> ⚙️ **Google Colab con GPU T4 requerido.** Entorno de ejecución → Cambiar tipo → **GPU**\n\n> 💡 Si la sesión de Colab se reinicia, sube `reviews_traducidas.csv` y el Notebook saltará la traducción automáticamente.", "objetivo"),
    cell_md("## 0 · Setup y GPU", "s0_t"), cell_code(S0_SETUP, "s0_setup"),
    cell_md("---\n## Parte A · Carga y Limpieza del Dataset\n\n**A.1** Carga el CSV y trunca cada review a 120 palabras antes de traducir.", "s1_t"), cell_code(S1_LOAD, "s1_load"),
    cell_md("---\n## Parte B · Traducción Masiva EN → ES\n\n**B.1** Traduce el corpus con `Helsinki-NLP/opus-mt-en-es`. Si existe un caché (`reviews_traducidas.csv`) lo carga directamente sin re-traducir.", "s2_t"), cell_code(S2_TRANSLATE, "s2_translate"),
    cell_md("**B.2** División train/test (80/20).", "s3_t"), cell_code(S3_SPLIT, "s3_split"),
    cell_md("---\n## Parte C · Tokenización con BETO\n\n**C.1** BETO recibe ahora texto en **español nativo**. La tokenización será óptima ya que el vocabulario del tokenizer coincide con el idioma de entrada.", "s4_t"), cell_code(S4_DATASET, "s4_dataset"),
    cell_md("---\n## Parte D · Arquitectura del Modelo\n\n**D.1** `BETORegressor` toma el vector `[CLS]` y aplica una cabeza de regresión de dos capas:\n$$\\hat{y} = \\sigma(W_2 \\cdot \\text{ReLU}(W_1 \\cdot h_{[CLS]} + b_1) + b_2), \\quad \\hat{y} \\in [0,1]$$", "s5_t"), cell_code(S5_MODEL, "s5_model"),
    cell_md("---\n## Parte E · Fine-tuning\n\n**E.1** Loop con barras de progreso en tiempo real. Learning rate diferenciado: BETO aprende lento (`2e-5`), la cabeza de regresión aprende rápido (`1e-3`).", "s6_t"), cell_code(S6_TRAIN, "s6_train"),
    cell_md("---\n## Parte F · Inferencia en Español\n\n**F.1** El modelo ahora entiende directamente español. No se requiere traducción en inferencia.", "s7_t"), cell_code(S7_INFER, "s7_infer"),
    cell_md("---\n## Parte G · Exportación y Despliegue\n\n**G.1** Guarda `modelo_predictivo.pt` y lo descarga a tu computadora.", "s8_t"), cell_code(S8_SAVE, "s8_save"),
]

nb = {
    "cells": cells,
    "metadata": {
        "kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
        "language_info": {"name": "python", "version": "3.10.0"},
        "colab": {"provenance": [], "gpuType": "T4"},
        "accelerator": "GPU"
    },
    "nbformat": 4,
    "nbformat_minor": 5
}

OUTPUT = 'motor_predictivo_v2_colab.ipynb'
with open(OUTPUT, 'w', encoding='utf-8') as f:
    json.dump(nb, f, ensure_ascii=False, indent=2)

print(f'✅ Notebook generado: {OUTPUT}')
