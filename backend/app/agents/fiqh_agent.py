from typing import Dict, Any, Optional, List
import json
import re
from .base_agent import BaseAgent
import logging

logger = logging.getLogger(__name__)

class FiqhAgent(BaseAgent):
    """Specialized agent for Islamic jurisprudence - uses fiqh_corpus.json"""
    
    def __init__(self):
        super().__init__(name="fiqh_agent")  # ✅ FIXED
        self.fiqh_data = self.load_dataset()
        logger.info(f"✅ FiqhAgent initialized with {len(self.fiqh_data)} rulings")
        
    def load_dataset(self) -> List[Dict]:
        """Load fiqh corpus from fiqh_corpus.json"""
        data = self.load_json_file('fiqh_corpus.json')
        if not data:
            logger.warning("⚠️ No fiqh data found, using sample data")
            return self._get_sample_fiqh_data()
        return data
    
    def _get_sample_fiqh_data(self) -> List[Dict]:
        """Sample fiqh data for fallback"""
        return [
            {
                "id": "fiqh_prayer_001",
                "category": "prayer",
                "subcategory": "wudu",
                "question_en": "What breaks wudu?",
                "question_bn": "ওজু ভাঙার কারণ কী?",
                "madhab": "hanafi",
                "ruling": "makruh_tahrimi",
                "ruling_display_en": "Makruh Tahrimi (Strongly Disliked)",
                "ruling_display_bn": "মাকরুহে তাহরিমী (কঠোরভাবে নিন্দিত)",
                "answer_en": "According to Hanafi fiqh, wudu is broken by: (1) Anything exiting from front or back passage, (2) Deep sleep, (3) Loss of consciousness, (4) Touching one's private parts with palm (without barrier), (5) Apostasy.",
                "answer_bn": "হানাফি ফিকহ অনুযায়ী ওজু ভাঙে: (১) পায়খানা-পেশাব বের হলে, (২) গভীর ঘুম, (৩) জ্ঞান হারালে, (৪) হস্তদ্বারা নিজের গোপন অঙ্গ স্পর্শ করলে, (৫) কুফরিতে লিপ্ত হলে।",
                "dalil": {
                    "quran": ["4:43", "5:6"],
                    "hadith": [{"book": "Sahih Muslim", "number": "271"}]
                }
            }
        ]
    
    def process_query(self, query: str, context: Optional[Dict] = None) -> Dict[str, Any]:
        """Process fiqh-related queries"""
        logger.info(f"⚖️ FiqhAgent processing: {query}")
        
        response = {
            'text': '',
            'sources': [],
            'citations': [],
            'agent': self.name  # ✅ FIXED
        }
        
        # Search in fiqh corpus
        search_fields = ['question_en', 'question_bn', 'answer_en', 'answer_bn', 'category', 'subcategory']
        results = self.search_dataset(self.fiqh_data, query, search_fields)
        
        if results:
            response['text'] = self._format_fiqh_response(results[:2], query)
            for result in results[:2]:
                response['citations'].append({
                    'source': 'Fiqh Ruling',
                    'madhab': result.get('madhab', 'Unknown'),
                    'category': result.get('category', 'General'),
                    'type': 'fiqh'
                })
                
                # Add Quran citations
                if result.get('dalil', {}).get('quran'):
                    for verse in result['dalil']['quran']:
                        response['citations'].append({
                            'source': 'Quran',
                            'reference': verse,
                            'type': 'quran'
                        })
                
                # Add Hadith citations
                if result.get('dalil', {}).get('hadith'):
                    for hadith in result['dalil']['hadith']:
                        response['citations'].append({
                            'source': hadith.get('book', 'Hadith'),
                            'reference': hadith.get('number', ''),
                            'type': 'hadith'
                        })
        else:
            response['text'] = self._get_general_fiqh_response(query)
        
        return self.format_citations(response)
    
    def _format_fiqh_response(self, results: List[Dict], query: str) -> str:
        """Format fiqh response"""
        text = "📜 **Islamic Jurisprudence (Fiqh) Response**\n\n"
        
        for i, result in enumerate(results, 1):
            if result.get('question_en'):
                text += f"❓ **Question:** {result['question_en']}\n\n"
            
            if result.get('madhab'):
                text += f"🕌 **Madhab:** {result['madhab'].title()}\n"
            
            if result.get('ruling_display_en'):
                text += f"⚖️ **Ruling:** {result['ruling_display_en']}\n\n"
            
            if result.get('answer_en'):
                text += f"📝 **Answer:**\n{result['answer_en']}\n\n"
            
            if result.get('dalil'):
                text += "📖 **Evidences:**\n"
                
                if result['dalil'].get('quran'):
                    text += f"• Quran: {', '.join(result['dalil']['quran'])}\n"
                
                if result['dalil'].get('hadith'):
                    for hadith in result['dalil']['hadith']:
                        text += f"• Hadith: {hadith.get('book', '')} #{hadith.get('number', '')}\n"
                
                text += "\n"
            
            if result.get('category'):
                text += f"🏷️ **Category:** {result['category'].title()}"
                if result.get('subcategory'):
                    text += f" / {result['subcategory'].title()}"
                text += "\n\n"
        
        return text
    
    def _get_general_fiqh_response(self, query: str) -> str:
        """Get general fiqh response"""
        return (
            "📜 **Fiqh Inquiry**\n\n"
            "I can provide Islamic legal rulings on various topics. Please ask about:\n\n"
            "• **Prayer (Salah):** Wudu, times, conditions, invalidators\n"
            "• **Fasting (Sawm):** Rules, exceptions, invalidators\n"
            "• **Zakat:** Calculation, recipients, nisab\n"
            "• **Hajj & Umrah:** Rituals, conditions\n"
            "• **Marriage (Nikah):** Conditions, rights, divorce\n"
            "• **Business:** Contracts, interest, trade\n"
            "• **Food:** Halal, haram, slaughter\n\n"
            "Please specify which madhab (Hanafi, Shafi'i, etc.) you follow."
        )