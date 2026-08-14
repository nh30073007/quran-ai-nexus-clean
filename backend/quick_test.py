"""
Quick test script for Quran AI Nexus API
Run this after starting the server
"""

import requests
import json
import sys

BASE_URL = "http://localhost:8000"

def print_response(title, response):
    print(f"\n{'='*50}")
    print(f"📌 {title}")
    print(f"{'='*50}")
    print(f"Status: {response.status_code}")
    try:
        data = response.json()
        print(f"Response: {json.dumps(data, indent=2, ensure_ascii=False)[:500]}...")
    except:
        print(f"Response: {response.text[:500]}")
    return response

def test_all():
    print("\n🚀 QURAN AI NEXUS - Quick Test")
    print("="*50)
    
    # 1. Health Check
    try:
        resp = requests.get(f"{BASE_URL}/health")
        if resp.status_code != 200:
            print("❌ Server not running! Start with: uvicorn app.main:app --reload")
            return False
        print("✅ Server is running")
    except:
        print("❌ Cannot connect to server. Make sure it's running.")
        return False
    
    # 2. Root
    resp = requests.get(f"{BASE_URL}/")
    print_response("Root Endpoint", resp)
    
    # 3. Login
    resp = requests.post(
        f"{BASE_URL}/auth/login",
        data={"username": "admin", "password": "admin123"}
    )
    print_response("Admin Login", resp)
    
    if resp.status_code == 200:
        token = resp.json().get("access_token")
        headers = {"Authorization": f"Bearer {token}"}
        
        # 4. Search
        resp = requests.get(f"{BASE_URL}/quran/search?query=mercy&top_k=2")
        print_response("Quran Search", resp)
        
        # 5. Ask
        resp = requests.post(
            f"{BASE_URL}/quran/ask",
            json={"query": "What is patience?", "language": "en"}
        )
        print_response("Ask Quran", resp)
        
        # 6. Guidance
        resp = requests.post(
            f"{BASE_URL}/guidance/life",
            json={"topic": "life", "feeling": "lost", "language": "en"}
        )
        print_response("Life Guidance", resp)
    
    print("\n✅ Testing complete!")
    return True

if __name__ == "__main__":
    success = test_all()
    sys.exit(0 if success else 1)