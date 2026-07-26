import io
import logging

import fitz
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.responses import JSONResponse

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="PDF Extractor", version="1.0.0")

MAX_FILE_SIZE = 10 * 1024 * 1024


def extract_text_from_pdf(content: bytes) -> str:
    doc = fitz.open(stream=content, filetype="pdf")
    pages = []
    for page in doc:
        pages.append(page.get_text("text"))
    doc.close()
    return "\n".join(pages).strip()


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/extract")
async def extract_pdf(file: UploadFile = File(...)):
    if not file.filename:
        raise HTTPException(status_code=400, detail="Nom de fichier manquant")

    content = await file.read()
    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(status_code=413, detail="Fichier trop volumineux (max 10 Mo)")

    if not content[:4] == b"%PDF":
        raise HTTPException(status_code=400, detail="Le fichier n'est pas un PDF valide")

    try:
        text = extract_text_from_pdf(content)
    except Exception as exc:
        logger.exception("Erreur extraction PDF")
        raise HTTPException(status_code=422, detail=f"Impossible d'extraire le texte: {exc}") from exc

    if not text:
        raise HTTPException(status_code=422, detail="Aucun texte extrait du PDF (PDF scanné ?)")

    return JSONResponse(
        {
            "filename": file.filename,
            "text": text,
            "char_count": len(text),
        }
    )
