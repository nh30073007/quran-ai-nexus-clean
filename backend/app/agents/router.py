from typing import Dict, Any, Optional, List
import re
from enum import Enum
import logging
from .base_agent import BaseAgent

# Safe imports — যদি কোনো agent file না থাকে তাহলে crash করবে না
try:
    from .tafsir_agent import TafsirAgent
except ImportError:
    TafsirAgent = None

try:
    from .fiqh_agent import FiqhAgent
except ImportError:
    FiqhAgent = None

try:
    from .spiritual_agent import SpiritualAgent
except ImportError:
    SpiritualAgent = None

try:
    from .hadith_agent import HadithAgent
except ImportError:
    HadithAgent = None

logger = logging.getLogger(__name__)


class IntentType(str, Enum):
    TAFSIR = "tafsir"
    FIQH = "fiqh"
    SPIRITUAL = "spiritual"
    HADITH = "hadith"
    GENERAL = "general"
    UNKNOWN = "unknown"


class AgentRouter:
    """Routes queries to appropriate agents based on intent classification"""
    
    def __init__(self):
        self.agents = {}
        self.agent_names = []
        
        # Initialize all available agents
        if TafsirAgent:
            tafsir_agent = TafsirAgent()
            self.agents[IntentType.TAFSIR] = tafsir_agent
            self.agents[IntentType.GENERAL] = tafsir_agent  # GENERAL uses Tafsir
            self.agent_names.append("tafsir_agent")
            logger.info("✅ TafsirAgent loaded")
        
        if FiqhAgent:
            self.agents[IntentType.FIQH] = FiqhAgent()
            self.agent_names.append("fiqh_agent")
            logger.info("✅ FiqhAgent loaded")
        
        if SpiritualAgent:
            self.agents[IntentType.SPIRITUAL] = SpiritualAgent()
            self.agent_names.append("spiritual_agent")
            logger.info("✅ SpiritualAgent loaded")
        
        if HadithAgent:
            self.agents[IntentType.HADITH] = HadithAgent()
            self.agent_names.append("hadith_agent")
            logger.info("✅ HadithAgent loaded")
        
        # Verify required agent exists
        if IntentType.TAFSIR not in self.agents:
            logger.error("❌ TafsirAgent is required but not found!")
            raise RuntimeError("TafsirAgent is required but not found!")
        
        logger.info(f"✅ AgentRouter initialized with {len(self.agents)} agents")
        
        # Advanced intent detection patterns
        self.intent_patterns = {
            IntentType.TAFSIR: [
                r'(\d+):(\d+)',  # Surah:Verse
                r'(?:verse|ayah|surah|chapter)\s+(\d+)',
                r'(?:tafsir|explain|meaning|interpret)\s+(?:of|for)\s+(?:verse|ayah|surah)',
                r'(?:what does|what is|meaning of)\s+(?:verse|ayah)',
                r'(?:quran|qur\'an)\s+(?:says|states|mentions)',
                r'(?:allāh|allah)\s+(?:says|states)',
                r'[\u0600-\u06FF]',
                r'তাফসীর', r'আয়াত', r'সূরা', r'ব্যাখ্যা', r'ভাবার্থ',
            ],
            IntentType.FIQH: [
                r'(?:halal|haram|makruh|mustahab|mubah|fard|wajib|sunnah)',
                r'(?:fiqh|jurisprudence|ruling|fatwa|sharia|islamic law)',
                r'(?:prayer|salah|namaz|wudu|ablution|tayammum)',
                r'(?:fasting|sawm|ramadan|iftar|suhoor)',
                r'(?:zakat|charity|sadaqah|fitr|nisab)',
                r'(?:hajj|umrah|tawaf|sa\'i|ihram)',
                r'(?:marriage|nikah|talaq|divorce|iddah|mehr|dower)',
                r'(?:inheritance|mirath|will|wasiyyah)',
                r'(?:business|trade|riba|interest|contract|sale)',
                r'(?:food|slaughter|dhabihah)',
                r'(?:can i|is it allowed|is it permissible|is it forbidden)',
                r'ফিকহ', r'হালাল', r'হারাম', r'ওয়াজিব', r'ফরজ', r'মাসআলা',
            ],
            IntentType.SPIRITUAL: [
                r'(?:dua|supplication|dhikr|zikr|remembrance)',
                r'(?:spiritual|soul|heart|inner peace|tazkiyah|purification)',
                r'(?:anxiety|stress|depression|worry|fear|hope|patience|sabr)',
                r'(?:gratitude|shukr|thankful|repentance|tawbah|forgiveness)',
                r'(?:sufi|sufism|rumi|ibn arabi|mystical)',
                r'(?:love|ishq|divine love|longing|yearning)',
                r'(?:guidance|spiritual guidance|wisdom|insight)',
                r'(?:pain|suffering|hardship|trial|test)',
                r'(?:broken|hurt|sad|crying|struggling|dealing with)',
                r'(?:what should i|how to (?:deal|cope|handle|overcome))',
                r'রুহানি', r'প্রশান্তি', r'দুঃখ', r'চিন্তা', r'আল্লাহর ভালোবাসা',
                r'রুমি', r'গাজালি', r'ইবনে আরাবী', r'ধ্যান', r'জিকির',
            ],
            IntentType.HADITH: [
                r'(?:hadith|sunnah|prophet|muhammad|pbuh|saw)',
                r'(?:bukhari|muslim|tirmidhi|abudawud|nasai|ibnmajah|ahmad|malik)',
                r'(?:narrated|reported|transmitted)\s+(?:by|from)',
                r'(?:prophetic\s+tradition|saying\s+of\s+the\s+prophet)',
                r'hadith\s+[\#\d]',
                r'(?:authentic|sahih|hasan|da\'if)\s+hadith',
                r'হাদিস', r'বুখারি', r'মুসলিম',
            ]
        }
        
        # Keyword weights
        self.keyword_weights = {
            IntentType.TAFSIR: {
                'verse': 3, 'ayah': 3, 'surah': 3, 'tafsir': 4,
                'explain': 2, 'mean': 2, 'interpret': 2, 'quran': 2,
                'তাফসীর': 4, 'আয়াত': 3, 'সূরা': 3,
            },
            IntentType.FIQH: {
                'halal': 4, 'haram': 4, 'fiqh': 4, 'ruling': 3,
                'prayer': 2, 'salah': 2, 'fasting': 2, 'zakat': 2,
                'permissible': 3, 'forbidden': 3, 'allowed': 2,
                'হালাল': 4, 'হারাম': 4, 'ফরজ': 3, 'ওয়াজিব': 3,
            },
            IntentType.SPIRITUAL: {
                'dua': 3, 'spiritual': 4, 'soul': 3, 'heart': 3,
                'patience': 2, 'sabr': 2, 'love': 2, 'guidance': 2,
                'pain': 2, 'broken': 3, 'healing': 3,
                'দুঃখ': 4, 'হতাশ': 4, 'প্রশান্তি': 3, 'রুমি': 3,
            },
            IntentType.HADITH: {
                'hadith': 4, 'prophet': 3, 'sunnah': 3, 'bukhari': 4,
                'muslim': 4, 'narrated': 2,
                'হাদিস': 4, 'বুখারি': 4,
            }
        }
    
    def classify_intent(self, query: str) -> IntentType:
        """Advanced intent classification with weighted scoring"""
        query_lower = query.lower()
        query_cleaned = re.sub(r'[^\w\s:]', ' ', query_lower)
        
        # Initialize scores
        scores = {intent: 0 for intent in IntentType}
        
        # Pattern matching
        for intent, patterns in self.intent_patterns.items():
            for pattern in patterns:
                if re.search(pattern, query_cleaned, re.IGNORECASE):
                    scores[intent] += 3
                    matches = len(re.findall(pattern, query_cleaned, re.IGNORECASE))
                    if matches > 1:
                        scores[intent] += matches
        
        # Keyword-based scoring
        for intent, keywords in self.keyword_weights.items():
            for keyword, weight in keywords.items():
                if keyword in query_cleaned:
                    scores[intent] += weight
        
        # Special cases
        if re.search(r'\d+:\d+', query_cleaned):
            scores[IntentType.TAFSIR] += 10
        
        if re.search(r'[\u0600-\u06FF]', query):
            scores[IntentType.TAFSIR] += 8
        
        emotional_words = ['sad', 'hurt', 'broken', 'pain', 'crying', 'depressed', 'anxiety', 'stress',
                          'দুঃখ', 'হতাশ', 'কষ্ট', 'চিন্তা', 'বিষণ্ণ']
        for word in emotional_words:
            if word in query_cleaned:
                scores[IntentType.SPIRITUAL] += 4
        
        if re.search(r'hadith\s*[\#\d]+\s*(?:bukhari|muslim)', query_cleaned):
            scores[IntentType.HADITH] += 8
        
        if re.search(r'(?:can i|is it|am i allowed|is it permissible|is it haram|is it halal)', query_cleaned):
            scores[IntentType.FIQH] += 4
        
        # Find top scoring intent
        max_score = max(scores.values())
        
        if max_score == 0:
            return IntentType.GENERAL
        
        top_intents = [intent for intent, score in scores.items() if score == max_score]
        
        if len(top_intents) == 1:
            return top_intents[0]
        else:
            priority = [IntentType.TAFSIR, IntentType.FIQH, IntentType.SPIRITUAL, IntentType.HADITH]
            for p in priority:
                if p in top_intents:
                    return p
            return top_intents[0]
    
    def get_agent_for_intent(self, intent: IntentType):
        """Returns the appropriate agent instance."""
        agent = self.agents.get(intent)
        if not agent:
            # Try GENERAL as fallback
            agent = self.agents.get(IntentType.GENERAL)
            if not agent:
                # Ultimate fallback to TAFSIR
                agent = self.agents.get(IntentType.TAFSIR)
                if agent:
                    logger.warning(f"No agent found for {intent}, falling back to tafsir_agent")
                else:
                    logger.error(f"❌ No agent found for {intent} and no fallback available")
        return agent
    
    def route_query(self, query: str, context: Optional[Dict] = None) -> Dict[str, Any]:
        """Route query to appropriate agent and get response"""
        try:
            intent = self.classify_intent(query)
            logger.info(f"🎯 Classified intent: {intent.value} for query: {query[:100]}...")
            
            if intent == IntentType.UNKNOWN:
                intent = IntentType.GENERAL
            
            # Check for force_intent in context
            if context and context.get('force_intent'):
                force_intent_str = context['force_intent']
                for intent_type in IntentType:
                    if intent_type.value == force_intent_str:
                        logger.info(f"🔄 Force intent: {force_intent_str}")
                        intent = intent_type
                        break
            
            agent = self.get_agent_for_intent(intent)
            
            if agent is None:
                return {
                    'text': "I apologize, but the AI service is currently unavailable. Please try again later.",
                    'intent': intent.value,
                    'agent': 'none',
                    'error': 'No agent available'
                }
            
            # Safely get agent name
            agent_name = getattr(agent, 'name', agent.__class__.__name__)
            logger.info(f"🤖 Using agent: {agent_name}")
            
            try:
                # Process query with agent
                response = agent.process_query(query, context or {})
            except Exception as e:
                logger.error(f"❌ Agent processing error: {e}")
                import traceback
                traceback.print_exc()
                return {
                    'text': f"I encountered an error while processing your request: {str(e)}",
                    'intent': intent.value,
                    'agent': agent_name,
                    'error': str(e)
                }
            
            # Convert to dict if needed
            if hasattr(response, 'dict'):
                response = response.dict()
            elif hasattr(response, 'model_dump'):
                response = response.model_dump()
            
            # Ensure response is a dict
            if not isinstance(response, dict):
                response = {
                    'text': str(response),
                    'sources': [],
                    'citations': []
                }
            
            # Add metadata
            response['intent'] = intent.value
            response['agent'] = agent_name
            response['confidence'] = self._calculate_confidence(query, intent)
            
            # Ensure text exists
            if 'text' not in response or not response.get('text'):
                response['text'] = "I couldn't generate a response. Please try rephrasing your question."
            
            logger.info(f"✅ Response generated by {agent_name}")
            return response
            
        except Exception as e:
            logger.error(f"❌ Error in route_query: {e}")
            import traceback
            traceback.print_exc()
            return {
                'text': f"I apologize, but I encountered an error: {str(e)}. Please try again.",
                'intent': 'error',
                'agent': 'error',
                'error': str(e)
            }
    
    def _calculate_confidence(self, query: str, intent: IntentType) -> float:
        """Calculate confidence score for intent classification"""
        query_lower = query.lower()
        score = 0
        max_possible = 0
        
        patterns = self.intent_patterns.get(intent, [])
        for pattern in patterns:
            max_possible += 3
            if re.search(pattern, query_lower, re.IGNORECASE):
                score += 3
        
        keywords = self.keyword_weights.get(intent, {})
        for keyword, weight in keywords.items():
            max_possible += weight
            if keyword in query_lower:
                score += weight
        
        confidence = min(score / max_possible if max_possible > 0 else 0, 1.0)
        
        if intent == IntentType.TAFSIR and re.search(r'\d+:\d+', query_lower):
            confidence = min(confidence + 0.2, 1.0)
        
        return round(confidence, 2)


# ✅ Single instance
agent_router = AgentRouter()