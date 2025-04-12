
from sentence_transformers import SentenceTransformer, util
from sklearn.ensemble import IsolationForest

# Load model
model = SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')

# --- Description Matching ---
desc1 = "Lost black iPhone with red case"
desc2 = "iPhone, red cover, black color"

embedding1 = model.encode(desc1, convert_to_tensor=True)
embedding2 = model.encode(desc2, convert_to_tensor=True)

similarity = util.cos_sim(embedding1, embedding2)
print(f"Description Similarity: {similarity.item():.4f}")

# --- Score Matching ---
seeker_text = "Seeker lost a Samsung phone in building A at 2 PM"
finder_text = "Found Samsung phone near Building A around 2"

seeker_embed = model.encode(seeker_text, convert_to_tensor=True)
finder_embed = model.encode(finder_text, convert_to_tensor=True)

score_similarity = util.cos_sim(seeker_embed, finder_embed)
print(f"Seeker-Finder Score Similarity: {score_similarity.item():.4f}")

# --- Anomaly Detection ---
entries = [
    "Lost wallet in the cafeteria at noon",
    "Lost MacBook in library at 3 PM",
    "Found shoes in gym",
    "suspicious entry zzz999@#$$@"
]

X = [model.encode(e) for e in entries]
iso = IsolationForest(contamination=0.2)
iso.fit(X)

preds = iso.predict(X)
for entry, pred in zip(entries, preds):
    status = "Anomaly" if pred == -1 else "Normal"
    print(f"{entry} => {status}")
