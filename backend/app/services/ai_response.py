from typing import List, Dict, Optional, Any
from .embeddings import QuranEmbeddingService
from app.agents.router import agent_router, IntentType
import logging

logger = logging.getLogger(__name__)

class AIResponseService:
    def __init__(self):
        try:
            self.embedding_service = QuranEmbeddingService()
            logger.info("✅ AIResponseService initialized with embeddings")
        except Exception as e:
            logger.error(f"❌ Failed to initialize embeddings: {e}")
            self.embedding_service = None
        
        try:
            from app.agents.router import agent_router
            self.agent_router = agent_router
        except Exception as e:
            logger.error(f"❌ Failed to initialize agent router: {e}")
            self.agent_router = None
    
    # ==================== MAIN METHODS ====================
    
    async def generate_response(self, query: str, context: Optional[Dict] = None) -> Dict[str, Any]:
        """Generate response using semantic search + agents"""
        logger.info(f"🚀 generate_response: {query[:50]}...")
        
        try:
            # Step 1: Get relevant verses using semantic search
            verses = []
            if self.embedding_service:
                verses = self.embedding_service.search_with_fallback(query, top_k=5)
                logger.info(f"📚 Found {len(verses)} relevant verses")
            else:
                # Fallback: use TafsirAgent search
                from app.agents.tafsir_agent import TafsirAgent
                agent = TafsirAgent()
                verses = agent.search_dataset(
                    agent.quran_data,
                    query,
                    ['translation_en', 'surah_name', 'text_arabic']
                )
            
            # Step 2: Classify intent
            intent = self.agent_router.classify_intent(query) if self.agent_router else IntentType.GENERAL
            
            # Step 3: Get agent response
            agent = self.agent_router.get_agent_for_intent(intent) if self.agent_router else None
            
            if agent:
                response = agent.process_query(query, context or {})
            else:
                response = {'text': 'No agent available', 'sources': [], 'citations': []}
            
            # Step 4: Enhance with semantic verses
            if verses and not response.get('text'):
                response['text'] = self._build_enhanced_response(query, verses, intent)
            
            # Step 5: Add verse references
            if not response.get('verses'):
                response['verses'] = []
                for v in verses[:3]:
                    response['verses'].append({
                        'surah_number': v.get('surah_number'),
                        'surah_name': v.get('surah_name'),
                        'verse_number': v.get('verse_number'),
                        'text_arabic': v.get('text_arabic'),
                        'translation_en': v.get('translation_en'),
                        'score': v.get('_score', 0)
                    })
            
            # Step 6: Add metadata
            response['intent'] = intent.value if hasattr(intent, 'value') else 'general'
            response['agent'] = agent.name if agent else 'unknown'
            
            # Set confidence from verses
            if verses:
                confidence = max([v.get('_score', 0) for v in verses[:3]])
                response['confidence'] = confidence
                response['score'] = confidence
            else:
                response['confidence'] = 0.7
                response['score'] = 0.7
            
            response['verified'] = True
            response['suggested_followups'] = self._get_followups(query, intent)
            
            # Ensure text is not empty
            if not response.get('text') or response['text'] == '':
                response['text'] = self._build_enhanced_response(query, verses, intent)
            
            return response
            
        except Exception as e:
            logger.error(f"❌ Error in generate_response: {e}")
            import traceback
            traceback.print_exc()
            return {
                'text': f"I apologize, but I encountered an error: {str(e)}. Please try again.",
                'intent': 'error',
                'agent': 'error',
                'error': str(e),
                'confidence': 0.0,
                'score': 0.0,
                'verified': False,
                'verses': [],
                'citations': [],
                'sources': [],
                'suggested_followups': []
            }
    
    # ==================== CHAT RESPONSE (FIXED) ====================
    
    async def chat_response(self, query: str, history: List[Dict[str, str]]) -> Dict[str, Any]:
        """Chat response with conversation history"""
        logger.info(f"💬 chat_response: {query[:50]}...")
        logger.info(f"📜 History length: {len(history)}")
        
        try:
            # Build context from history
            context = {'history': history}
            
            # Get response
            response = await self.generate_response(query, context)
            
            # Add history to response
            response['history'] = history + [
                {'role': 'user', 'content': query},
                {'role': 'assistant', 'content': response.get('text', '')}
            ]
            
            return response
            
        except Exception as e:
            logger.error(f"❌ Error in chat_response: {e}")
            import traceback
            traceback.print_exc()
            return {
                'text': f"I apologize, but I encountered an error: {str(e)}. Please try again.",
                'intent': 'error',
                'agent': 'error',
                'error': str(e),
                'history': history,
                'confidence': 0.0,
                'score': 0.0,
                'verified': False,
                'verses': [],
                'citations': [],
                'sources': [],
                'suggested_followups': []
            }
    
    # ==================== LEGACY METHODS ====================
    
    async def ask_quran(self, query: str) -> Dict[str, Any]:
        """Legacy method - redirects to generate_response"""
        return await self.generate_response(query)
    
    async def get_fiqh_ruling(self, query: str) -> Dict[str, Any]:
        """Legacy method - force FIQH agent"""
        if self.agent_router:
            return self.agent_router.route_query(query, {'force_intent': 'fiqh'})
        return {'text': 'Agent router not available', 'intent': 'error', 'agent': 'error'}
    
    async def get_spiritual_guidance(self, query: str) -> Dict[str, Any]:
        """Legacy method - force SPIRITUAL agent"""
        if self.agent_router:
            return self.agent_router.route_query(query, {'force_intent': 'spiritual'})
        return {'text': 'Agent router not available', 'intent': 'error', 'agent': 'error'}
    
    async def get_hadith(self, query: str) -> Dict[str, Any]:
        """Legacy method - force HADITH agent"""
        if self.agent_router:
            return self.agent_router.route_query(query, {'force_intent': 'hadith'})
        return {'text': 'Agent router not available', 'intent': 'error', 'agent': 'error'}
    
    # ==================== HELPER METHODS ====================
    
    def _build_enhanced_response(self, query: str, verses: List[Dict], intent: IntentType) -> str:
        """Build enhanced response from semantic search results"""
        if not verses:
            return "I couldn't find specific verses. Please try rephrasing your question."
        
        response = f"📖 **Response to: \"{query}\"**\n\n"
        
        # Add best matching verse
        top_verse = verses[0]
        response += f"**Relevant Verse:** {top_verse.get('surah_name')} {top_verse.get('verse_number')}\n"
        response += f"*Translation:* {top_verse.get('translation_en', '')}\n\n"
        
        # Add tafsir if available
        if top_verse.get('tafsir', {}).get('ibn_kathir'):
            response += f"**Tafsir (Ibn Kathir):**\n{top_verse['tafsir']['ibn_kathir']}\n\n"
        
        if top_verse.get('tafsir', {}).get('jalalayn'):
            response += f"**Tafsir (Jalalayn):**\n{top_verse['tafsir']['jalalayn']}\n\n"
        
        # Add sufi insights if available
        if top_verse.get('sufi', {}).get('rumi'):
            response += f"**Sufi Insight (Rumi):**\n{top_verse['sufi']['rumi']}\n\n"
        
        # Add more verses
        if len(verses) > 1:
            response += "**Related Verses:**\n"
            for v in verses[1:3]:
                response += f"• {v.get('surah_name')} {v.get('verse_number')}: {v.get('translation_en', '')[:100]}...\n"
        
        return response
    
    def _get_followups(self, query: str, intent: IntentType) -> List[str]:
        """Generate suggested follow-up questions"""
        followups = [
            "Can you explain more about this?",
            "What is the context of this verse?",
            "Show me similar verses",
        ]
        
        if intent == IntentType.TAFSIR:
            followups.extend([
                "What does the tafsir say?",
                "Give me more details about this verse",
                "What is the Arabic text?"
            ])
        elif intent == IntentType.FIQH:
            followups.extend([
                "What is the ruling on this?",
                "Is there any difference of opinion?",
                "What does other madhabs say?"
            ])
        elif intent == IntentType.SPIRITUAL:
            followups.extend([
                "Give me more spiritual guidance",
                "What would Rumi say about this?",
                "Give me a dua for this"
            ])
        elif intent == IntentType.HADITH:
            followups.extend([
                "What does Bukhari say?",
                "Give me more hadiths on this topic"
            ])
        
        return followups[:5]  # Return top 5


# ✅ Single instance
ai_response_service = AIResponseService()