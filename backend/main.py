"""
FastAPI Backend for Smart Product and Medicine Expiry Management System
Integrates with existing Flutter app without breaking functionality
"""

from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, Dict, Any, List
import sqlite3
import json
import re
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI
app = FastAPI(
    title="Expiry Management API",
    description="Backend for Smart Product and Medicine Expiry Management System",
    version="1.0.0"
)

# CORS Middleware (for Flutter app)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Database setup
DB_PATH = "expiry_management.db"

def init_db():
    """Initialize SQLite database with required tables"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Create items table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,  -- 'medicine' or 'product'
            brand TEXT,
            dosage TEXT,
            doctor_name TEXT,
            expiry_date TEXT,
            prescription_image TEXT,
            barcode TEXT,
            mrp TEXT,
            batch TEXT,
            manufacturer TEXT,
            extra_data TEXT,  -- JSON for dynamic fields
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    
    conn.commit()
    conn.close()

# Pydantic Models
class ProcessRequest(BaseModel):
    raw_text: str
    barcode: Optional[str] = None
    category: Optional[str] = None  # 'medicine' or 'product'
    gemini_data: Optional[Dict[str, Any]] = None  # Pre-processed by Gemini

class ProcessResponse(BaseModel):
    success: bool
    data: Dict[str, Any]
    message: Optional[str] = None

class SyncRequest(BaseModel):
    name: str
    category: str  # 'medicine' or 'product'
    brand: Optional[str] = None
    dosage: Optional[str] = None
    doctor_name: Optional[str] = None
    expiry_date: Optional[str] = None
    prescription_image: Optional[str] = None
    barcode: Optional[str] = None
    mrp: Optional[str] = None
    batch: Optional[str] = None
    manufacturer: Optional[str] = None
    extra_data: Optional[str] = None

class ItemResponse(BaseModel):
    id: int
    name: str
    category: str
    brand: Optional[str]
    dosage: Optional[str]
    doctor_name: Optional[str]
    expiry_date: Optional[str]
    prescription_image: Optional[str]
    barcode: Optional[str]
    mrp: Optional[str]
    batch: Optional[str]
    manufacturer: Optional[str]
    extra_data: Optional[str]
    created_at: str
    updated_at: str

# Data Processing Functions
def extract_medicine_info(text: str, barcode: Optional[str] = None) -> Dict[str, Any]:
    """Extract medicine information from raw text"""
    result = {
        "name": "",
        "brand": "",
        "dosage": "",
        "doctor_name": "",
        "expiry_date": "",
        "batch": "",
        "manufacturer": "",
        "method": "backend_extracted"
    }
    
    # Extract medicine name (first line or capitalized words)
    lines = text.strip().split('\n')
    if lines:
        result["name"] = lines[0].strip()
    
    # Extract dosage (common patterns)
    dosage_patterns = [
        r'(\d+(?:\.\d+)?)\s*(?:mg|ml|g|mcg|tablet|capsule|syrup)',
        r'(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)\s*(?:mg|ml|g)',
    ]
    
    for pattern in dosage_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            result["dosage"] = match.group(0)
            break
    
    # Extract expiry date (multiple formats)
    expiry_patterns = [
        r'exp[.:]?\s*(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
        r'expiry[.:]?\s*(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
        r'exp[.:]?\s*(\d{2,4}[/-]\d{1,2}[/-]\d{1,2})',
        r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
    ]
    
    for pattern in expiry_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            date_str = match.group(1)
            # Normalize date format
            try:
                if '/' in date_str:
                    parts = date_str.split('/')
                elif '-' in date_str:
                    parts = date_str.split('-')
                
                if len(parts) == 3:
                    # Convert to YYYY-MM-DD format
                    if len(parts[2]) == 2:
                        parts[2] = '20' + parts[2]
                    result["expiry_date"] = f"{parts[2]}-{parts[1].zfill(2)}-{parts[0].zfill(2)}"
                    break
            except:
                pass
    
    # Extract batch number
    batch_patterns = [
        r'batch[.:]?\s*([A-Za-z0-9]+)',
        r'lot[.:]?\s*([A-Za-z0-9]+)',
        r'b\.?[nN]o[.:]?\s*([A-Za-z0-9]+)',
    ]
    
    for pattern in batch_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            result["batch"] = match.group(1)
            break
    
    # Extract brand/manufacturer
    brand_patterns = [
        r'by\s+([A-Za-z][A-Za-z\s&]+)',
        r'mfg[.:]?\s*([A-Za-z][A-Za-z\s&]+)',
        r'manufactured\s+by\s+([A-Za-z][A-Za-z\s&]+)',
    ]
    
    for pattern in brand_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            result["manufacturer"] = match.group(1).strip()
            result["brand"] = match.group(1).strip()
            break
    
    # Use barcode if provided
    if barcode:
        result["barcode"] = barcode
    
    return result

def extract_product_info(text: str, barcode: Optional[str] = None) -> Dict[str, Any]:
    """Extract product information from raw text"""
    result = {
        "name": "",
        "brand": "",
        "category": "",
        "variant": "",
        "mrp": "",
        "manufacturing_date": "",
        "expiry_date": "",
        "net_weight": "",
        "ingredients": "",
        "manufacturer_name": "",
        "batch_number": "",
        "method": "backend_extracted"
    }
    
    # Extract product name (first line or main title)
    lines = text.strip().split('\n')
    if lines:
        result["name"] = lines[0].strip()
    
    # Extract MRP/Price
    mrp_patterns = [
        r'mrp[.:]?\s*Rs?\.\s*(\d+(?:\.\d+)?)',
        r'price[.:]?\s*Rs?\.\s*(\d+(?:\.\d+)?)',
        r'Rs?\.\s*(\d+(?:\.\d+)?)',
        r'(\d+(?:\.\d+)?)\s*rs',
    ]
    
    for pattern in mrp_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            result["mrp"] = match.group(1)
            break
    
    # Extract weight/volume
    weight_patterns = [
        r'(\d+(?:\.\d+)?)\s*(?:g|kg|ml|l|mg|oz)',
        r'net\s+wt[.:]?\s*(\d+(?:\.\d+)?)\s*(?:g|kg|ml|l)',
    ]
    
    for pattern in weight_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            result["net_weight"] = match.group(0)
            break
    
    # Extract dates
    date_patterns = [
        r'mfg[.:]?\s*(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
        r'manufactured[.:]?\s*(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
        r'exp[.:]?\s*(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
    ]
    
    for pattern in date_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            date_str = match.group(1)
            field = "manufacturing_date" if "mfg" in pattern.lower() else "expiry_date"
            try:
                if '/' in date_str:
                    parts = date_str.split('/')
                elif '-' in date_str:
                    parts = date_str.split('-')
                
                if len(parts) == 3:
                    if len(parts[2]) == 2:
                        parts[2] = '20' + parts[2]
                    result[field] = f"{parts[2]}-{parts[1].zfill(2)}-{parts[0].zfill(2)}"
                    break
            except:
                pass
    
    # Extract batch number
    batch_patterns = [
        r'batch[.:]?\s*([A-Za-z0-9]+)',
        r'lot[.:]?\s*([A-Za-z0-9]+)',
    ]
    
    for pattern in batch_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            result["batch_number"] = match.group(1)
            break
    
    return result

# API Endpoints
@app.on_event("startup")
async def startup_event():
    """Initialize database on startup"""
    init_db()
    logger.info("FastAPI backend started and database initialized")

@app.post("/process", response_model=ProcessResponse)
async def process_data(request: ProcessRequest):
    """
    Process raw text and barcode data
    If Gemini data is provided, validate and normalize it
    Otherwise, extract using backend logic
    """
    try:
        logger.info(f"Processing request: category={request.category}, barcode={request.barcode}")
        
        # If Gemini already processed the data, validate and normalize it
        if request.gemini_data:
            logger.info("Using Gemini pre-processed data")
            data = request.gemini_data.copy()
            data["method"] = "gemini_validated"
            
            # Validate required fields
            if not data.get("name"):
                data["name"] = extract_medicine_info(request.raw_text, request.barcode).get("name", "Unknown Item")
        else:
            # Use backend extraction logic
            logger.info("Using backend extraction logic")
            if request.category == "medicine":
                data = extract_medicine_info(request.raw_text, request.barcode)
            else:
                data = extract_product_info(request.raw_text, request.barcode)
        
        # Add metadata
        data["processed_at"] = datetime.now().isoformat()
        data["backend_version"] = "1.0.0"
        
        logger.info(f"Processing completed: {data.get('name', 'Unknown')}")
        
        return ProcessResponse(
            success=True,
            data=data,
            message="Data processed successfully"
        )
        
    except Exception as e:
        logger.error(f"Processing error: {str(e)}")
        return ProcessResponse(
            success=False,
            data={},
            message=f"Processing failed: {str(e)}"
        )

@app.post("/sync")
async def sync_item(request: SyncRequest):
    """Sync item to backend database"""
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO items (
                name, category, brand, dosage, doctor_name, expiry_date,
                prescription_image, barcode, mrp, batch, manufacturer,
                extra_data, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            request.name,
            request.category,
            request.brand,
            request.dosage,
            request.doctor_name,
            request.expiry_date,
            request.prescription_image,
            request.barcode,
            request.mrp,
            request.batch,
            request.manufacturer,
            request.extra_data,
            datetime.now()
        ))
        
        item_id = cursor.lastrowid
        conn.commit()
        conn.close()
        
        logger.info(f"Item synced successfully: {request.name} (ID: {item_id})")
        
        return {
            "success": True,
            "item_id": item_id,
            "message": "Item synced successfully"
        }
        
    except Exception as e:
        logger.error(f"Sync error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Sync failed: {str(e)}")

@app.get("/items", response_model=List[ItemResponse])
async def get_items(category: Optional[str] = None):
    """Get all items, optionally filtered by category"""
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        if category:
            cursor.execute("SELECT * FROM items WHERE category = ? ORDER BY created_at DESC", (category,))
        else:
            cursor.execute("SELECT * FROM items ORDER BY created_at DESC")
        
        items = cursor.fetchall()
        conn.close()
        
        result = []
        for item in items:
            result.append(ItemResponse(
                id=item[0],
                name=item[1],
                category=item[2],
                brand=item[3],
                dosage=item[4],
                doctor_name=item[5],
                expiry_date=item[6],
                prescription_image=item[7],
                barcode=item[8],
                mrp=item[9],
                batch=item[10],
                manufacturer=item[11],
                extra_data=item[12],
                created_at=item[13],
                updated_at=item[14]
            ))
        
        logger.info(f"Retrieved {len(result)} items")
        return result
        
    except Exception as e:
        logger.error(f"Get items error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve items: {str(e)}")

@app.delete("/items/{item_id}")
async def delete_item(item_id: int):
    """Delete an item by ID"""
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute("DELETE FROM items WHERE id = ?", (item_id,))
        affected_rows = cursor.rowcount
        
        conn.commit()
        conn.close()
        
        if affected_rows == 0:
            raise HTTPException(status_code=404, detail="Item not found")
        
        logger.info(f"Item deleted successfully: ID {item_id}")
        
        return {
            "success": True,
            "message": f"Item {item_id} deleted successfully"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Delete error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Delete failed: {str(e)}")

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": "1.0.0"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
