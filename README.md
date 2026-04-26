# KoffyBoy Official — Artist Platform

A full-stack artist management platform for **KoffyBoy Official**.

## Project Structure

```
KoffyBoyOfficial/
├── frontend/        # Public-facing website (HTML/CSS/JS)
├── backend/         # Flask REST API + WebSocket server
└── artist_app/      # Flutter mobile dashboard (Android/iOS)
```

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | HTML5, CSS3, Vanilla JS |
| Backend | Python · Flask · Flask-SocketIO · SQLite |
| Mobile | Flutter (Dart) |
| AI | Google Gemini API |

## Backend Setup (Local)

```bash
cd backend
python -m venv venv
./venv/Scripts/activate   # Windows
pip install -r requirements.txt
python app.py
```

Server runs on `http://0.0.0.0:5000`

## EC2 Deployment

See `docs/` for deployment guide.

---

© KoffyBoy Official
