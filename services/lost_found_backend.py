from fastapi import FastAPI, APIRouter, UploadFile, File, HTTPException, Request
from pydantic import BaseModel, Field
from typing import Dict, Optional
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime
from uuid import uuid4
from difflib import SequenceMatcher
import google.generativeai as genai
import cloudinary
import cloudinary.uploader
import firebase_admin
from firebase_admin import credentials, firestore
import json
import os
import traceback
import magic
from dotenv import load_dotenv

# === Load environment variables ===
load_dotenv()

# === Cloudinary Configuration ===
cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
    api_key=os.getenv("CLOUDINARY_API_KEY"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET"),
    secure=True
)

# === Firebase Initialization ===
cred = credentials.Certificate(os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON"))
firebase_admin.initialize_app(cred, {
    'projectId': os.getenv("FIREBASE_PROJECT_ID")
})
db = firestore.client()

# === Gemini Configuration ===
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
model = genai.GenerativeModel("gemini-1.5-flash")

# === FastAPI Setup ===
app = FastAPI()
router = APIRouter()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# === Pydantic Models ===
class AnswerInput(BaseModel):
    item_id: str
    answers: Dict[str, str]
    finder_id: Optional[str] = Field(None)

class MatchRequest(BaseModel):
    item_id: str
    user_answers: Dict[str, str]
    user_id: str

class ChatMessage(BaseModel):
    sender_id: str
    sender_name: str  # ✅ NEW FIELD
    message: str

# === Utility Functions ===
def similarity_ratio(a: str, b: str) -> float:
    return SequenceMatcher(None, a.strip().lower(), b.strip().lower()).ratio()

async def upload_to_cloudinary(file: UploadFile) -> tuple:
    try:
        content = await file.read()
        mime_type = magic.from_buffer(content, mime=True)
        result = cloudinary.uploader.upload(
            content,
            resource_type="image",
            folder="foundit/item_images"
        )
        return result["secure_url"], content, mime_type
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(
            status_code=500, 
            detail=f"Cloudinary upload failed: {str(e)}"
        )

# === API Routes ===
@router.post("/gemini/analyze")
async def analyze_item_image(image: UploadFile = File(...)):
    try:
        image_url, content, mime_type = await upload_to_cloudinary(image)

        prompt = """
You are an AI tasked with verifying the ownership of lost items based on an image.
Generate exactly 5 clear, concise, and objective questions...
        """.strip()

        response = model.generate_content([
            prompt,
            {
                "mime_type": mime_type,
                "data": content
            }
        ])

        response_text = response.text.strip()
        if response_text.startswith("```json"):
            response_text = response_text.split("```json")[1].split("```")[0].strip()
        questions = json.loads(response_text)

        if not isinstance(questions, list) or len(questions) != 5:
            raise ValueError("Gemini returned invalid question list")

        item_id = str(uuid4())
        db.collection("found_items").document(item_id).set({
            "id": item_id,
            "image_url": image_url,
            "questions": questions,
            "correct_answers": {},
            "timestamp": datetime.utcnow(),
            "is_claimed": False,
            "claims": [],
            "finder_id": None
        })

        return {"item_id": item_id, "questions": questions, "image_url": image_url}

    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Gemini processing failed: {str(e)}")

@router.post("/gemini/answer-key")
async def submit_answer_key(data: AnswerInput):
    ref = db.collection("found_items").document(data.item_id)
    item = ref.get()
    if not item.exists:
        raise HTTPException(status_code=404, detail="Item not found")

    update_data = {"correct_answers": data.answers}
    if data.finder_id:
        update_data["finder_id"] = data.finder_id

    ref.update(update_data)
    return {"message": "Answers saved successfully"}

@router.post("/evaluate-match")
async def evaluate_match(req: MatchRequest):
    ref = db.collection("found_items").document(req.item_id)
    item = ref.get()
    if not item.exists:
        raise HTTPException(status_code=404, detail="Item not found")

    data = item.to_dict()
    correct = data.get("correct_answers", {})

    matched = sum(
        1 for q in correct 
        if similarity_ratio(correct[q], req.user_answers.get(q, "")) > 0.85
    )
    score = matched / len(correct) if correct else 0
    verified = score >= 0.85

    attempt = {
        "attempt_id": str(uuid4()),
        "user_id": req.user_id,
        "score": round(score, 2),
        "verified": verified,
        "timestamp": datetime.utcnow()
    }

    ref.update({
        "claims": firestore.ArrayUnion([attempt]),
        "is_claimed": verified
    })

    if verified and data.get("finder_id"):
        db.collection("chats").document(req.item_id).set({
            "item_id": req.item_id,
            "finder_id": data["finder_id"],
            "claimer_id": req.user_id,
            "created_at": datetime.utcnow(),
            "lastMessage": "",
            "lastMessageTime": None,
            "userIds": [data["finder_id"], req.user_id]
        })

    return {
        "match": verified,
        "score": round(score, 2),
        "show_image": verified,
        "image_url": data["image_url"] if verified else None,
        "chat_enabled": verified
    }

@router.post("/chat/send")
async def send_chat_message(item_id: str, message: ChatMessage):
    chat_ref = db.collection("chats").document(item_id)
    if not chat_ref.get().exists:
        raise HTTPException(status_code=404, detail="Chat not found")

    chat_ref.collection("messages").add({
        "sender_id": message.sender_id,
        "sender_name": message.sender_name,  # ✅ NOW STORED
        "message": message.message,
        "timestamp": datetime.utcnow()
    })

    chat_ref.update({
        "last_updated": datetime.utcnow(),
        "lastMessage": message.message,
        "lastMessageTime": datetime.utcnow()
    })

    return {"status": "Message sent"}

@router.get("/chat/{item_id}")
async def get_chat_history(item_id: str, limit: int = 100):
    chat_ref = db.collection("chats").document(item_id)
    if not chat_ref.get().exists:
        raise HTTPException(status_code=404, detail="Chat not found")

    messages = []
    docs = chat_ref.collection("messages").order_by("timestamp").limit(limit).stream()

    for doc in docs:
        msg = doc.to_dict()
        msg["id"] = doc.id
        messages.append(msg)

    return messages

@router.get("/items/{item_id}")
async def get_item(item_id: str):
    doc = db.collection("found_items").document(item_id).get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Item not found")

    data = doc.to_dict()
    data.pop("correct_answers", None)
    return data

@app.middleware("http")
async def log_requests(request, call_next):
    print(f"Incoming request: {request.method} {request.url}")
    response = await call_next(request)
    print(f"Response: {response.status_code}")
    return response

# === Mount Router ===
app.include_router(router)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
