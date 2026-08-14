import json
import os
import re
from typing import List, Dict, Any

class FiqhSearchService:
    """
    Searches fiqh corpus with madhab-aware filtering.
    Critical: Always routes complex issues to scholars.
    """
    
    def __init__(self, data_path: str = None):
        if data_path is None:
            base_dir = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
            data_path = os.path.join(base_dir, "data", "fiqh_corpus.json")
        
        self.data_path = data_path
        self.corpus = self._load_corpus()
    
    def _load_corpus(self) -> List[Dict]:
        if not os.path.exists(self.data_path):
            return []
        with open(self.data_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    
    def search(self, query: str, madhab: str = "hanafi", language: str = "en", top_k: int = 3) -> List[Dict]:
        """
        Search fiqh corpus with madhab preference.
        """
        query_lower = query.lower()
        query_words = set(re.findall(r'\w+', query_lower))
        
        scored = []
        for item in self.corpus:
            score = 0
            
            # Question matching (highest priority)
            question_field = item.get("question_en", "") if language == "en" else item.get("question_bn", "")
            if any(word in question_field.lower() for word in query_words):
                score += 10
            
            # Category match
            if item.get("category", "").lower() in query_lower:
                score += 5
            if item.get("subcategory", "").lower() in query_lower:
                score += 5
            
            # Tags match
            for tag in item.get("tags", []):
                if tag.lower() in query_lower:
                    score += 3
            
            # Madhab match (boost if matches user's madhab)
            item_madhab = item.get("madhab", "all").lower()
            if item_madhab == madhab.lower() or item_madhab == "all":
                score += 2
            
            # Answer content match
            answer_field = item.get("answer_en", "") if language == "en" else item.get("answer_bn", "")
            for word in query_words:
                if word in answer_field.lower():
                    score += 1
            
            if score > 0:
                scored.append((score, item))
        
        scored.sort(key=lambda x: x[0], reverse=True)
        return [item for _, item in scored[:top_k]]
    
    def get_by_category(self, category: str, madhab: str = "hanafi", limit: int = 5) -> List[Dict]:
        results = []
        for item in self.corpus:
            if item.get("category", "").lower() == category.lower():
                if item.get("madhab", "all").lower() in [madhab.lower(), "all"]:
                    results.append(item)
                    if len(results) >= limit:
                        break
        return results
    
    def get_critical_warnings(self, query: str) -> List[str]:
        """Check if query touches topics that ALWAYS need scholar verification"""
        critical_topics = [
            r'inheritance', r'mirath', r'ত্রাস্ত', r'ওয়ারিশ', r'সম্পত্তি ভাগ',
            r'divorce procedure', r'triple talaq', r'খুল', r'তালাব প্রক্রিয়া',
            r'zakat calculation', r'যাকাত হিসাব', r'complex business',
            r'criminal law', r'hudud', r'কিসাস', r'দিয়াত',
            r'apostasy', r'রিদ্দত', r'blasphemy',
        ]
        warnings = []
        query_lower = query.lower()
        for topic in critical_topics:
            if re.search(topic, query_lower):
                warnings.append("⚠️ This topic requires consultation with a qualified scholar. AI response is for educational purposes only.")
        return warnings

fiqh_search_service = FiqhSearchService()