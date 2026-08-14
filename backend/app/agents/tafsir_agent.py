from typing import Dict, Any, Optional, List
import json
import re
from .base_agent import BaseAgent
import logging

logger = logging.getLogger(__name__)

class TafsirAgent(BaseAgent):
    """Specialized agent for Quran Tafsir - uses quran_en1.json dataset"""
    
    def __init__(self):
        super().__init__(name="tafsir_agent")
        self.quran_data = self.load_dataset()
        logger.info(f"✅ TafsirAgent initialized with {len(self.quran_data)} verses")
        
    def load_dataset(self) -> List[Dict]:
        data = self.load_json_file('quran_en1.json')
        if not data:
            logger.warning("⚠️ No data found, using sample data")
            return self._get_sample_quran_data()
        return data
    
    def _get_sample_quran_data(self) -> List[Dict]:
        return [
            {
                "ayah_id": 1,
                "surah_number": 1,
                "surah_name": "Al-Fatiha",
                "verse_number": 1,
                "text_arabic": "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
                "translation_en": "In the name of Allah, the Entirely Merciful, the Especially Merciful.",
                "tafsir": {
                    "ibn_kathir": "This verse opens every Surah (except one) and signifies beginning with Allah's name, seeking His help and blessings.",
                    "jalalayn": "This verse means 'I begin with the Name of Allah'—the One worthy of worship."
                },
                "sufi": {
                    "rumi": "Every act should start with love for the Divine, for Bismillah opens the heart to mercy.",
                    "ibn_arabi": "The basmala reveals the hidden unity between creation and divine mercy."
                }
            }
        ]
    
    def process_query(self, query: str, context: Optional[Dict] = None) -> Dict[str, Any]:
        """Process tafsir-related queries with semantic search"""
        logger.info(f"📖 TafsirAgent processing: {query}")
        
        response = {
            'text': '',
            'sources': [],
            'citations': [],
            'agent': self.name,
            'intent': 'tafsir',
            'confidence': 0.85,
            'score': 0.85,
            'verified': True,
            'suggested_followups': [],
            'verse_reference': None,
            'verses': []
        }
        
        # Step 1: Check for specific verse reference
        verse_ref = self._extract_verse_reference(query)
        if verse_ref:
            result = self._get_verse_by_reference(verse_ref)
            if result:
                return self._build_verse_response(result, verse_ref, response)
        
        # Step 2: Try semantic search with embeddings
        semantic_results = self._semantic_search(query)
        if semantic_results:
            return self._build_semantic_response(semantic_results, query, response)
        
        # Step 3: Fallback to keyword search
        search_results = self.search_dataset(
            self.quran_data, 
            query, 
            ['translation_en', 'surah_name', 'text_arabic']
        )
        
        if search_results:
            return self._build_keyword_response(search_results, query, response)
        
        # Step 4: No results
        response['text'] = self._get_general_tafsir_response(query)
        response['confidence'] = 0.3
        response['score'] = 0.3
        response['verified'] = False
        return response
    
    def _semantic_search(self, query: str) -> List[Dict]:
        """Perform semantic search using embeddings"""
        try:
            from app.services.embeddings import QuranEmbeddingService
            embedding_service = QuranEmbeddingService()
            results = embedding_service.search_with_fallback(query, top_k=5)
            return results
        except Exception as e:
            logger.warning(f"⚠️ Semantic search failed: {e}")
            return []
    
    def _build_verse_response(self, verse: Dict, verse_ref: str, response: Dict) -> Dict:
        """Build response for specific verse"""
        response['verse_reference'] = verse_ref
        response['text'] = f"📖 **{verse.get('surah_name', 'Unknown')} {verse.get('verse_number', '?')}**\n\n"
        response['text'] += f"**Arabic:** {verse.get('text_arabic', '')}\n\n"
        response['text'] += f"**Translation:** {verse.get('translation_en', '')}\n\n"
        
        if verse.get('tafsir'):
            response['text'] += self._format_tafsir(verse['tafsir'])
            response['citations'].append({
                'source': 'Tafsir Ibn Kathir',
                'reference': verse_ref,
                'type': 'tafsir',
                'source_ref': f'Ibn Kathir on {verse_ref}'
            })
        
        if verse.get('sufi'):
            response['text'] += self._format_sufi_insights(verse['sufi'])
            response['citations'].append({
                'source': 'Rumi',
                'reference': verse_ref,
                'type': 'sufi',
                'source_ref': f'Rumi on {verse_ref}'
            })
        
        response['verses'].append({
            'surah_number': verse.get('surah_number'),
            'surah_name': verse.get('surah_name'),
            'verse_number': verse.get('verse_number'),
            'translation_en': verse.get('translation_en'),
        })
        
        response['suggested_followups'] = [
            f"Explain more about {verse_ref}",
            "What is the context?",
            "Show me similar verses",
            "What does Ibn Kathir say?"
        ]
        response['confidence'] = 0.95
        response['score'] = 0.95
        return self.format_citations(response)
    
    def _build_semantic_response(self, results: List[Dict], query: str, response: Dict) -> Dict:
        """Build response from semantic search results"""
        response['text'] = f"📖 **Response to: \"{query}\"**\n\n"
        
        for i, verse in enumerate(results[:3], 1):
            surah = verse.get('surah_name', 'Unknown')
            num = verse.get('verse_number', '?')
            translation = verse.get('translation_en', '')
            score = verse.get('_score', 0)
            
            response['text'] += f"**{i}. {surah} {num}**\n"
            response['text'] += f"*{translation}*\n"
            response['text'] += f"_(Relevance: {int(score * 100)}%)_\n\n"
            
            # Add tafsir if available
            if verse.get('tafsir', {}).get('ibn_kathir'):
                response['text'] += f"💡 {verse['tafsir']['ibn_kathir'][:150]}...\n\n"
            
            response['citations'].append({
                'source': 'Quran',
                'reference': f"{surah} {num}",
                'type': 'quran',
                'source_ref': f"{surah} {num}"
            })
            
            response['verses'].append({
                'surah_number': verse.get('surah_number'),
                'surah_name': surah,
                'verse_number': num,
                'translation_en': translation,
                'score': score
            })
        
        response['suggested_followups'] = [
            "Explain more about these verses",
            "What is the context?",
            "Show me more verses on this topic",
            "What does the tafsir say?"
        ]
        response['confidence'] = results[0].get('_score', 0.5)
        response['score'] = response['confidence']
        return self.format_citations(response)
    
    def _build_keyword_response(self, results: List[Dict], query: str, response: Dict) -> Dict:
        """Build response from keyword search results"""
        response['text'] = f"🔍 **Search results for: '{query}'**\n\n"
        
        for i, result in enumerate(results[:3], 1):
            surah = result.get('surah_name', 'Unknown')
            num = result.get('verse_number', '?')
            translation = result.get('translation_en', '')
            
            response['text'] += f"{i}. **{surah} {num}**\n"
            response['text'] += f"   {translation[:200]}...\n\n"
            
            response['citations'].append({
                'source': 'Quran',
                'reference': f"{surah} {num}",
                'type': 'quran',
                'source_ref': f"{surah} {num}"
            })
            
            response['verses'].append({
                'surah_number': result.get('surah_number'),
                'surah_name': surah,
                'verse_number': num,
                'translation_en': translation,
            })
        
        response['suggested_followups'] = [
            "Tell me more about these verses",
            "What does the tafsir say?",
            "Show me more verses on this topic"
        ]
        response['confidence'] = 0.6
        response['score'] = 0.6
        return self.format_citations(response)
    
    def _extract_verse_reference(self, query: str) -> Optional[str]:
        patterns = [
            r'(\d+):(\d+)',
            r'surah\s+(\d+)\s+verse\s+(\d+)',
            r'verse\s+(\d+)\s+of\s+surah\s+(\d+)',
            r'chapter\s+(\d+)\s+verse\s+(\d+)',
            r'(\d+)\s+:\s+(\d+)',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, query, re.IGNORECASE)
            if match and len(match.groups()) == 2:
                return f"{match.group(1)}:{match.group(2)}"
        return None
    
    def _get_verse_by_reference(self, ref: str) -> Optional[Dict]:
        try:
            surah_num, verse_num = map(int, ref.split(':'))
            for verse in self.quran_data:
                if verse.get('surah_number') == surah_num and verse.get('verse_number') == verse_num:
                    return verse
        except:
            pass
        return None
    
    def _format_tafsir(self, tafsir: Dict) -> str:
        text = "**📚 Tafsir:**\n\n"
        if tafsir.get('ibn_kathir'):
            text += f"**Ibn Kathir:** {tafsir['ibn_kathir']}\n\n"
        if tafsir.get('jalalayn'):
            text += f"**Jalalayn:** {tafsir['jalalayn']}\n\n"
        return text
    
    def _format_sufi_insights(self, sufi: Dict) -> str:
        text = "**✨ Sufi Insights:**\n\n"
        if sufi.get('rumi'):
            text += f"**Rumi:** {sufi['rumi']}\n\n"
        if sufi.get('ibn_arabi'):
            text += f"**Ibn Arabi:** {sufi['ibn_arabi']}\n\n"
        return text
    
    def _get_general_tafsir_response(self, query: str) -> str:
        return (
            "I can help you understand Quranic verses. Please specify:\n\n"
            "• A specific verse reference like '1:1' or 'surah 1 verse 1'\n"
            "• A topic or keyword to search in the Quran\n"
            "• Ask 'What is the meaning of [surah name]'\n\n"
            "For example:\n"
            "• 'Explain Surah Al-Fatiha verse 1'\n"
            "• 'What does Quran say about patience?'\n"
            "• 'Show me verses about mercy'"
        )