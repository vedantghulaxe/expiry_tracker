# FastAPI Backend for Expiry Management System

## Setup Instructions

### 1. Install Dependencies
```bash
pip install -r requirements.txt
```

### 2. Run the Backend
```bash
python main.py
```

The backend will start on `http://localhost:8000`

### 3. API Documentation
Visit `http://localhost:8000/docs` for interactive API documentation

## API Endpoints

### POST /process
Processes raw text and barcode data
- Accepts Gemini pre-processed data
- Validates and normalizes structured data
- Fallback to backend extraction if needed

### POST /sync
Saves items to backend database

### GET /items
Retrieves all items (optionally filtered by category)

### DELETE /items/{id}
Deletes an item by ID

### GET /health
Health check endpoint

## Integration with Flutter

The backend is designed to work alongside your existing Flutter app without breaking functionality.

## Database
Uses SQLite for simplicity. Database file: `expiry_management.db`
