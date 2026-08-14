from typing import Dict, Any, Optional, List
import json
import re
from .base_agent import BaseAgent
import logging

logger = logging.getLogger(__name__)

class HadithAgent(BaseAgent):
    """Specialized agent for Hadith - extracts hadith from fiqh corpus"""
    
    def __init__(self):
        super().__init__(name="hadith_agent")  # ✅ FIXED
        self.hadith_data = self.load_dataset()
        logger.info(f"✅ HadithAgent initialized with {len(self.hadith_data)} hadiths")
        
    def load_dataset(self) -> List[Dict]:
        """Extract hadith from fiqh_corpus.json"""
        fiqh_data = self.load_json_file('fiqh_corpus.json')
        hadiths = []
        
        for item in fiqh_data:
            if item.get('dalil', {}).get('hadith'):
                for hadith in item['dalil']['hadith']:
                    hadith_entry = {
                        'book': hadith.get('book', 'Unknown'),
                        'number': hadith.get('number', ''),
                        'text': hadith.get('text', ''),
                        'context': item.get('question_en', ''),
                        'category': item.get('category', 'General'),
                        'source_id': item.get('id', '')
                    }
                    hadiths.append(hadith_entry)
        
        if not hadiths:
            logger.warning("⚠️ No hadith data found, using sample data")
            return self._get_sample_hadith_data()
        return hadiths
    
    def _get_sample_hadith_data(self) -> List[Dict]:
        """Sample hadith data for fallback"""
        return [
            {
                "book": "Sahih Muslim",
                "number": "271",
                "text": "Allah does not accept the prayer of one who has hadath until he performs wudu...",
                "context": "Conditions of prayer",
                "category": "prayer"
            }
        ]
    
    def process_query(self, query: str, context: Optional[Dict] = None) -> Dict[str, Any]:
        """Process hadith-related queries"""
        logger.info(f"📜 HadithAgent processing: {query}")
        
        response = {
            'text': '',
            'sources': [],
            'citations': [],
            'agent': self.name  # ✅ FIXED
        }
        
        # Search in hadith data
        search_fields = ['book', 'text', 'context', 'category']
        results = self.search_dataset(self.hadith_data, query, search_fields)
        
        if results:
            response['text'] = self._format_hadith_response(results[:3], query)
            for result in results[:3]:
                response['citations'].append({
                    'source': result.get('book', 'Hadith'),
                    'reference': result.get('number', ''),
                    'category': result.get('category', 'General'),
                    'type': 'hadith'
                })
        else:
            response['text'] = self._get_general_hadith_response(query)
        
        return self.format_citations(response)
    
    def _format_hadith_response(self, results: List[Dict], query: str) -> str:
        """Format hadith response"""
        text = "📜 **Prophetic Traditions (Hadith)**\n\n"
        
        for i, result in enumerate(results, 1):
            text += f"{i}. **{result.get('book', 'Unknown')}**"
            if result.get('number'):
                text += f" #{result['number']}"
            text += "\n"
            
            if result.get('text'):
                text += f"   *\"{result['text']}\"*\n"
            
            if result.get('context'):
                text += f"   💡 Context: {result['context']}\n"
            
            if result.get('category'):
                text += f"   🏷️ Category: {result['category']}\n"
            
            text += "\n"
        
        text += "📌 *Hadith are sayings, actions, and approvals of Prophet Muhammad (PBUH).*"
        return text
    
    def _get_general_hadith_response(self, query: str) -> str:
        """Get general hadith response"""
        return (
            "📜 **Hadith Inquiry**\n\n"
            "I can provide authentic prophetic traditions. Please ask about:\n\n"
            "• A specific topic (prayer, charity, character, etc.)\n"
            "• A particular book (Bukhari, Muslim, etc.)\n"
            "• A specific hadith number\n\n"
            "For example: 'What does Bukhari say about sincerity?' or 'Hadith 271 Muslim'"
        )