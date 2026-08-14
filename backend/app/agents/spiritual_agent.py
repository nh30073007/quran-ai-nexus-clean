from typing import Dict, Any, Optional, List
import json
import re
from .base_agent import BaseAgent
import logging

logger = logging.getLogger(__name__)

class SpiritualAgent(BaseAgent):
    """Specialized agent for spiritual guidance - uses spiritual_corpus.json"""
    
    def __init__(self):
        super().__init__(name="spiritual_agent")  # ✅ FIXED
        self.spiritual_data = self.load_dataset()
        logger.info(f"✅ SpiritualAgent initialized with {len(self.spiritual_data)} entries")
        
    def load_dataset(self) -> List[Dict]:
        """Load spiritual corpus from spiritual_corpus.json"""
        data = self.load_json_file('spiritual_corpus.json')
        if not data:
            logger.warning("⚠️ No spiritual data found, using sample data")
            return self._get_sample_spiritual_data()
        return data
    
    def _get_sample_spiritual_data(self) -> List[Dict]:
        """Sample spiritual data for fallback"""
        return [
            {
                "id": "rumi_001",
                "source": "Rumi - Masnavi",
                "author": "Jalaluddin Rumi",
                "category": "divine_love",
                "tags": ["love", "heart", "allah"],
                "text_en": "The wound is the place where the Light enters you.",
                "text_bn": "যে ক্ষত সেখানেই আলো প্রবেশ করে।",
                "context": "Rumi speaks about how pain and suffering purify the soul.",
                "related_verses": ["2:286", "94:5-6"],
                "mood_tags": ["sad", "hurt", "broken"]
            }
        ]
    
    def process_query(self, query: str, context: Optional[Dict] = None) -> Dict[str, Any]:
        """Process spiritual guidance queries"""
        logger.info(f"✨ SpiritualAgent processing: {query}")
        
        response = {
            'text': '',
            'sources': [],
            'citations': [],
            'agent': self.name  # ✅ FIXED
        }
        
        # Search in spiritual corpus
        search_fields = ['text_en', 'text_bn', 'category', 'context', 'tags']
        results = self.search_dataset(self.spiritual_data, query, search_fields)
        
        # Also search by mood tags
        mood_results = self._search_by_mood(query)
        if mood_results:
            results.extend(mood_results)
            # Remove duplicates
            seen_ids = set()
            unique_results = []
            for r in results:
                if r.get('id') not in seen_ids:
                    seen_ids.add(r.get('id'))
                    unique_results.append(r)
            results = unique_results
        
        if results:
            response['text'] = self._format_spiritual_response(results[:3], query)
            for result in results[:3]:
                response['citations'].append({
                    'source': result.get('source', 'Spiritual Wisdom'),
                    'author': result.get('author', 'Unknown'),
                    'category': result.get('category', 'General'),
                    'type': 'spiritual'
                })
        else:
            response['text'] = self._get_compassionate_response(query)
        
        return self.format_citations(response)
    
    def _search_by_mood(self, query: str) -> List[Dict]:
        """Search spiritual corpus by mood tags"""
        mood_mapping = {
            'sad': ['sad', 'hurt', 'broken', 'pain', 'crying', 'depressed'],
            'anxious': ['anxious', 'stress', 'worry', 'fear', 'panic'],
            'hopeful': ['hope', 'optimistic', 'faith', 'trust'],
            'grateful': ['grateful', 'thankful', 'blessed']
        }
        
        query_lower = query.lower()
        matching_moods = []
        
        for mood, keywords in mood_mapping.items():
            if any(keyword in query_lower for keyword in keywords):
                matching_moods.append(mood)
        
        if not matching_moods:
            return []
        
        results = []
        for item in self.spiritual_data:
            item_moods = item.get('mood_tags', [])
            for mood in matching_moods:
                if mood in item_moods:
                    item['_match_score'] = 1
                    results.append(item)
                    break
        
        return results[:3]
    
    def _format_spiritual_response(self, results: List[Dict], query: str) -> str:
        """Format spiritual guidance response"""
        text = "✨ **Spiritual Guidance**\n\n"
        
        for i, result in enumerate(results, 1):
            text += f"{i}. **{result.get('author', 'Unknown')}** ({result.get('source', '')})\n"
            text += f"   *{result.get('text_en', '')}*\n"
            
            if result.get('context'):
                text += f"   💭 {result['context']}\n"
            
            if result.get('category'):
                text += f"   🏷️ Category: {result['category']}\n"
            
            if result.get('related_verses'):
                text += f"   📖 Related Quran: {', '.join(result['related_verses'])}\n"
            
            text += "\n"
        
        text += "💫 May these words bring peace and guidance to your heart."
        return text
    
    def _get_compassionate_response(self, query: str) -> str:
        """Get compassionate response for spiritual queries"""
        return (
            "🤲 **A Compassionate Response**\n\n"
            "I hear your concern, dear soul. In times of spiritual need, remember:\n\n"
            "• Allah is always near, closer than your jugular vein (50:16)\n"
            "• 'Indeed, with hardship comes ease' (94:5-6)\n"
            "• Turn to Allah in sincere dua, He listens to every prayer\n"
            "• Seek comfort in dhikr - the remembrance of Allah brings peace to hearts\n\n"
            "Would you like to hear wisdom from Rumi, Ibn Arabi, or other spiritual masters?"
        )