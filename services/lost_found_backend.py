from fastapi import FastAPI, APIRouter, UploadFile, File, HTTPException, Depends
from pydantic import BaseModel, Field
from typing import Dict, List, Optional
import google.generativeai as genai
import os
import base64
import json
from difflib import SequenceMatcher
from datetime import datetime
from uuid import uuid4
from fastapi.middleware.cors import CORSMiddleware
import firebase_admin
from firebase_admin import credentials, firestore, storage
import asyncio
import aiohttp

# Initialize Firebase
FIREBASE_CONFIG = {
    "apiKey": "AIzaSyA0rHx4NLSi2HpUHsRD5f9YQaI5IKQpMME",
    "authDomain": "founditapp-f63e5.firebaseapp.com",
    "projectId": "founditapp-f63e5",
    "storageBucket": "founditapp-f63e5.appspot.com",
    "messagingSenderId": "975298750134",
    "appId": "1:975298750134:web:7c6754e0038633dd9b6817"
}

# Initialize Firebase Admin SDK
cred = credentials.Certificate(json.loads(os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")))
firebase_admin.initialize_app(cred, {
    'storageBucket': FIREBASE_CONFIG["storageBucket"]
})

# Get Firestore and Storage clients
db = firestore.client()
bucket = storage.bucket()

# === FastAPI App Setup ===
app = FastAPI()
router = APIRouter()

# === CORS ===
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# === Gemini Configuration ===
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
model = genai.GenerativeModel("gemini-1.5-flash")

# === Pydantic Models ===
class AnswerInput(BaseModel):
    item_id: str
    answers: Dict[str, str]
    finder_id: Optional[str] = Field(None, description="ID of user who found the item")

class MatchRequest(BaseModel):
    item_id: str
    user_answers: Dict[str, str]
    user_id: str

class ChatMessage(BaseModel):
    sender_id: str
    message: str

# === Helper Functions ===
def similarity_ratio(a: str, b: str) -> float:
    a = a.strip().lower()
    b = b.strip().lower()
    return SequenceMatcher(None, a, b).ratio()

async def upload_to_firebase(file: UploadFile) -> str:
    """Upload file to Firebase Storage and return download URL"""
    file_content = await file.read()
    blob = bucket.blob(f"item_images/{uuid4()}_{file.filename}")
    
    # Upload file content
    blob.upload_from_string(
        file_content, 
        content_type=file.content_type
    )
    
    # Get download URL
    blob.make_public()
    return blob.public_url

async def store_chat_message(item_id: str, message: dict):
    """Store chat message in Firestore"""
    chat_ref = db.collection("chats").document(item_id)
    chat_ref.set({
        "participants": message.get("participants", {}),
        "last_updated": datetime.utcnow()
    }, merge=True)
    
    messages_ref = chat_ref.collection("messages")
    messages_ref.add({
        "sender_id": message["sender_id"],
        "message": message["message"],
        "timestamp": datetime.utcnow()
    })

# === Routes ===
@router.post("/gemini/analyze")
async def analyze_item_image(image: UploadFile = File(...)):
    try:
        # Upload image to Firebase Storage
        image_url = await upload_to_firebase(image)
        
        # Get image content for Gemini
        content = await image.read()
        
        # Generate questions with Gemini
        prompt = """
You are an assistant that creates ownership-verification questions for lost and found items.
Generate exactly 5 concise, specific, and answerable questions that would help verify a person's claim of ownership.
Output ONLY a valid JSON array of strings. Do not include any other text.
Example: ["What color is the main body?", "Is there any distinctive wear mark?", ...]
"""
        response = model.generate_content([
            prompt,
            genai.types.Blob(mime_type=image.content_type, data=content)
        ])
        
        # Clean Gemini response
        response_text = response.text.strip()
        if response_text.startswith("```json"):
            response_text = response_text[7:-3].strip()
        
        questions = json.loads(response_text)
        if not isinstance(questions, list) or len(questions) != 5:
            raise ValueError("Gemini response is not a valid list of 5 questions")

        # Create item in Firestore
        item_id = str(uuid4())
        item_ref = db.collection("found_items").document(item_id)
        item_ref.set({
            "id": item_id,
            "image_url": image_url,
            "questions": questions,
            "correct_answers": {},
            "timestamp": datetime.utcnow(),
            "is_claimed": False,
            "claims": [],
            "finder_id": None
        })
        
        return {"item_id": item_id, "questions": questions}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Gemini processing failed: {str(e)}")

@router.post("/gemini/answer-key")
async def submit_answer_key(data: AnswerInput):
    item_ref = db.collection("found_items").document(data.item_id)
    item = item_ref.get()
    
    if not item.exists:
        raise HTTPException(status_code=404, detail="Item not found")
    
    update_data = {"correct_answers": data.answers}
    if data.finder_id:
        update_data["finder_id"] = data.finder_id
    
    item_ref.update(update_data)
    return {"message": "Correct answers saved"}

@router.post("/evaluate-match")
async def evaluate_match(req: MatchRequest):
    item_ref = db.collection("found_items").document(req.item_id)
    item = item_ref.get()
    
    if not item.exists:
        raise HTTPException(status_code=404, detail="Item not found")
    
    item_data = item.to_dict()
    
    if not item_data.get("correct_answers"):
        raise HTTPException(status_code=400, detail="Answer key not set for this item")
    
    correct = item_data["correct_answers"]
    matched = 0
    total = len(correct)

    for q in correct:
        ratio = similarity_ratio(correct[q], req.user_answers.get(q, ""))
        if ratio > 0.85:
            matched += 1

    score = matched / total if total > 0 else 0
    verified = score >= 0.85

    # Create claim attempt
    attempt_id = str(uuid4())
    attempt_data = {
        "attempt_id": attempt_id,
        "user_id": req.user_id,
        "score": round(score, 2),
        "verified": verified,
        "timestamp": datetime.utcnow()
    }
    
    # Update item document
    updates = {
        "claims": firestore.ArrayUnion([attempt_data]),
        "is_claimed": verified or item_data.get("is_claimed", False)
    }
    
    # Create chat if verified
    if verified and item_data.get("finder_id"):
        chat_data = {
            "item_id": req.item_id,
            "finder_id": item_data["finder_id"],
            "claimer_id": req.user_id,
            "created_at": datetime.utcnow()
        }
        db.collection("chats").document(req.item_id).set(chat_data, merge=True)
    
    item_ref.update(updates)
    
    return {
        "match": verified,
        "score": round(score, 2),
        "show_image": verified,
        "image_url": item_data["image_url"] if verified else None,
        "attempt_id": attempt_id,
        "chat_enabled": verified
    }

@router.post("/chat/send")
async def send_chat_message(item_id: str, message: ChatMessage):
    chat_ref = db.collection("chats").document(item_id)
    chat = chat_ref.get()
    
    if not chat.exists:
        raise HTTPException(status_code=404, detail="Chat not found")
    
    # Add message to subcollection
    messages_ref = chat_ref.collection("messages")
    messages_ref.add({
        "sender_id": message.sender_id,
        "message": message.message,
        "timestamp": datetime.utcnow()
    })
    
    # Update last message timestamp
    chat_ref.update({"last_updated": datetime.utcnow()})
    
    return {"status": "message sent"}

@router.get("/chat/{item_id}")
async def get_chat_history(item_id: str, limit: int = 50):
    messages_ref = db.collection("chats").document(item_id).collection("messages")
    docs = messages_ref.order_by("timestamp", direction=firestore.Query.DESCENDING).limit(limit).stream()
    
    messages = []
    for doc in docs:
        msg = doc.to_dict()
        msg["id"] = doc.id
        messages.append(msg)
    
    # Return in chronological order
    return sorted(messages, key=lambda x: x["timestamp"])

@router.get("/items/{item_id}")
async def get_item(item_id: str):
    item_ref = db.collection("found_items").document(item_id)
    item = item_ref.get()
    
    if not item.exists:
        raise HTTPException(status_code=404, detail="Item not found")
    
    item_data = item.to_dict()
    
    # Don't expose answers
    if "correct_answers" in item_data:
        del item_data["correct_answers"]
    
    return item_data

# === Register Router ===
app.include_router(router)