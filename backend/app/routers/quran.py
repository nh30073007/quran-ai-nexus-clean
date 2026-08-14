from fastapi import APIRouter, HTTPException, Query
from typing import Optional, List, Dict, Any
from pydantic import BaseModel
import logging

from ..services.ai_response import ai_response_service
from ..agents.router import AgentRouter
from ..agents.tafsir_agent import TafsirAgent

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/quran", tags=["quran"])

# Request Models
class AskRequest(BaseModel):
    query: str
    language: Optional[str] = "en"
    context: Optional[Dict] = None

class ChatRequest(BaseModel):
    query: str
    history: Optional[List[Dict[str, str]]] = []
    language: Optional[str] = "en"

class QuranAskRequest(BaseModel):
    query: str
    context: Optional[Dict] = None


@router.post("/ask")
async def ask_quran(request: QuranAskRequest):
    """
    Ask any question about Quran - automatically routed to correct agent
    """
    try:
        query = request.query
        if not query:
            raise HTTPException(status_code=400, detail="Query is required")
        
        logger.info(f"📖 Quran Ask Request: {query}")
        
        # Try to get response with fallback
        try:
            response = await ai_response_service.generate_response(query, request.context)
        except Exception as e:
            logger.error(f"❌ AI Service error: {e}")
            import traceback
            traceback.print_exc()
            # Fallback response
            response = {
                'text': f"I received your question: '{query}'. However, I'm having trouble processing it. Please try again or rephrase your question.",
                'intent': 'fallback',
                'agent': 'fallback',
                'error': str(e)
            }
        
        return {
            "success": True,
            "data": response
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error in /quran/ask: {e}")
        import traceback
        traceback.print_exc()
        return {
            "success": False,
            "error": str(e),
            "data": {
                'text': f"Server error: {str(e)}. Please try again.",
                'intent': 'error',
                'agent': 'error'
            }
        }


@router.post("/chat")
async def chat_with_quran(request: ChatRequest):
    """
    Chat with AI about Quran with conversation history
    """
    try:
        query = request.query
        history = request.history or []
        
        if not query:
            raise HTTPException(status_code=400, detail="Query is required")
        
        logger.info(f"💬 Chat Request: {query}")
        logger.info(f"📜 History length: {len(history)}")
        
        # Generate response with history context
        try:
            response = await ai_response_service.chat_response(query, history)
        except Exception as e:
            logger.error(f"❌ Chat service error: {e}")
            import traceback
            traceback.print_exc()
            response = {
                'text': f"I received your message: '{query}'. However, I'm having trouble processing it. Please try again.",
                'intent': 'fallback',
                'agent': 'fallback',
                'history': history,
                'error': str(e)
            }
        
        return {
            "success": True,
            "data": response
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error in /quran/chat: {e}")
        import traceback
        traceback.print_exc()
        return {
            "success": False,
            "error": str(e),
            "data": {
                'text': f"Server error: {str(e)}. Please try again.",
                'intent': 'error',
                'agent': 'error',
                'history': request.history if request else []
            }
        }


@router.get("/search")
async def search_quran(
    query: str = Query(..., description="Search query"),
    limit: int = Query(5, description="Number of results"),
    language: str = Query("en", description="Language")
):
    """
    Search Quran verses by keyword
    """
    try:
        agent = TafsirAgent()
        
        # Search in Quran dataset
        results = agent.search_dataset(
            agent.quran_data,
            query,
            ['translation_en', 'surah_name', 'text_arabic']
        )
        
        # Format results
        formatted_results = []
        for r in results[:limit]:
            formatted_results.append({
                'surah_number': r.get('surah_number'),
                'surah_name': r.get('surah_name'),
                'verse_number': r.get('verse_number'),
                'text_arabic': r.get('text_arabic'),
                'translation_en': r.get('translation_en'),
                'match_score': r.get('_match_score', 0)
            })
        
        return {
            "success": True,
            "query": query,
            "total_results": len(results),
            "results": formatted_results
        }
    except Exception as e:
        logger.error(f"❌ Error in /quran/search: {e}")
        import traceback
        traceback.print_exc()
        return {
            "success": False,
            "error": str(e),
            "results": []
        }


@router.get("/verse/{surah}:{verse}")
async def get_verse(surah: int, verse: int):
    """
    Get specific verse by Surah:Verse number
    """
    try:
        agent = TafsirAgent()
        
        result = agent._get_verse_by_reference(f"{surah}:{verse}")
        
        if not result:
            raise HTTPException(status_code=404, detail=f"Verse {surah}:{verse} not found")
        
        # Remove internal fields
        result.pop('_match_score', None)
        result.pop('_matched_fields', None)
        
        return {
            "success": True,
            "data": result
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error in /quran/verse: {e}")
        import traceback
        traceback.print_exc()
        return {
            "success": False,
            "error": str(e)
        }


@router.get("/surah/{surah_number}")
async def get_surah(surah_number: int):
    """
    Get all verses of a specific Surah
    """
    try:
        agent = TafsirAgent()
        
        verses = [
            v for v in agent.quran_data 
            if v.get('surah_number') == surah_number
        ]
        
        if not verses:
            raise HTTPException(status_code=404, detail=f"Surah {surah_number} not found")
        
        # Remove internal fields
        for v in verses:
            v.pop('_match_score', None)
            v.pop('_matched_fields', None)
        
        return {
            "success": True,
            "surah_number": surah_number,
            "surah_name": verses[0].get('surah_name', 'Unknown'),
            "verses": verses,
            "total_verses": len(verses)
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error in /quran/surah: {e}")
        import traceback
        traceback.print_exc()
        return {
            "success": False,
            "error": str(e)
        }


@router.get("/intent/{query}")
async def detect_intent(query: str):
    """
    Test intent detection for a query
    """
    try:
        from ..agents.router import AgentRouter, IntentType
        router = AgentRouter()
        
        intent = router.classify_intent(query)
        confidence = router._calculate_confidence(query, intent)
        
        # Get all scores
        all_scores = {}
        for intent_type in IntentType:
            if intent_type != IntentType.UNKNOWN:
                all_scores[intent_type.value] = router._calculate_confidence(query, intent_type)
        
        return {
            "success": True,
            "query": query,
            "intent": intent.value,
            "confidence": confidence,
            "all_scores": all_scores
        }
    except Exception as e:
        logger.error(f"❌ Error in /quran/intent: {e}")
        import traceback
        traceback.print_exc()
        return {
            "success": False,
            "error": str(e)
        }