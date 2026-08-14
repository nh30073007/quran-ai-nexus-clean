import json
import os
from typing import List, Dict, Any
import re

class SpiritualSearchService:
    """
    Searches spiritual corpus (Rumi, Ghazali, Ibn Arabi, Hadith, Thematic Quran).
    This is separate from Quran FAISS search.
    """
    
    def __init__(self, data_path: str = None):
        if data_path is None:
            # Adjust path based on your structure
            base_dir = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
            data_path = os.path.join(base_dir, "data", "spiritual_corpus.json")
        
        self.data_path = data_path
        self.corpus = self._load_corpus()
    
    def _load_corpus(self) -> List[Dict]:
        if not os.path.exists(self.data_path):
            # Return minimal default if file doesn't exist yet
            return []
        with open(self.data_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    
    def search(self, query: str, language: str = "en", top_k: int = 3) -> List[Dict]:
        """
        Keyword-based search with scoring.
        In production, you can upgrade this to use embeddings + FAISS too.
        """
        query_lower = query.lower()
        query_words = set(re.findall(r'\w+', query_lower))
        
        scored = []
        for item in self.corpus:
            score = 0
            
            # Match tags
            for tag in item.get("tags", []):
                if tag.lower() in query_lower:
                    score += 3
            
            # Match mood_tags
            for mood in item.get("mood_tags", []):
                if mood.lower() in query_lower:
                    score += 4  # Mood match is highly relevant
            
            # Match text content
            text_to_search = item.get("text_en", "") + " " + item.get("text_bn", "")
            text_lower = text_to_search.lower()
            for word in query_words:
                if word in text_lower:
                    score += 1
            
            # Match category
            if item.get("category", "").lower() in query_lower:
                score += 2
            
            if score > 0:
                scored.append((score, item))
        
        # Sort by score descending
        scored.sort(key=lambda x: x[0], reverse=True)
        return [item for _, item in scored[:top_k]]
    
    def get_by_mood(self, mood: str, language: str = "en", limit: int = 3) -> List[Dict]:
        """Get spiritual content by mood (depressed, anxious, grateful, etc.)"""
        results = []
        for item in self.corpus:
            if mood.lower() in [m.lower() for m in item.get("mood_tags", [])]:
                results.append(item)
                if len(results) >= limit:
                    break
        return results
    
    def get_by_category(self, category: str, language: str = "en", limit: int = 3) -> List[Dict]:
        """Get by category: patience, divine_love, gratitude, hope, etc."""
        results = []
        for item in self.corpus:
            if item.get("category", "").lower() == category.lower():
                results.append(item)
                if len(results) >= limit:
                    break
        return results

# Global instance
spiritual_search_service = SpiritualSearchService()