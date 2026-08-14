from abc import ABC, abstractmethod
from typing import Dict, Any, Optional, List
from pydantic import BaseModel
import logging
import json
import os
import re

logger = logging.getLogger(__name__)

class AgentResponse(BaseModel):
    text: str
    sources: List[str] = []
    citations: List[Dict[str, str]] = []
    confidence: float = 0.0
    suggestions: List[str] = []
    metadata: Dict[str, Any] = {}

class BaseAgent(ABC):
    """Base class for all specialized agents"""
    
    def __init__(self, name: str = "base_agent"):
        self.name = name
        self.agent_type = self.__class__.__name__
        self.confidence_threshold = 0.7
        self.cache = {}
        self.data = []
        logger.info(f"🤖 Initialized {self.name} ({self.agent_type})")
        
    @abstractmethod
    def process_query(self, query: str, context: Optional[Dict] = None) -> Dict[str, Any]:
        """Process the user query and return response"""
        pass
    
    @abstractmethod
    def load_dataset(self) -> List[Dict]:
        """Load the agent's specific dataset"""
        pass
    
    def load_json_file(self, file_path: str) -> List[Dict]:
        """Generic JSON loader with comprehensive path search"""
        current_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.dirname(os.path.dirname(current_dir))
        
        possible_paths = [
            file_path,
            f'./data/{file_path}',
            f'../data/{file_path}',
            f'../../data/{file_path}',
            os.path.join(current_dir, 'data', file_path),
            os.path.join(current_dir, '../data', file_path),
            os.path.join(current_dir, '../../data', file_path),
            os.path.join(project_root, 'data', file_path),
            os.path.join(project_root, 'backend', 'data', file_path),
            '/app/data/' + file_path,
            '/app/backend/data/' + file_path,
            os.path.join(os.getcwd(), 'data', file_path),
            os.path.join(os.getcwd(), 'backend', 'data', file_path),
        ]
        
        seen = set()
        unique_paths = []
        for path in possible_paths:
            if path not in seen:
                seen.add(path)
                unique_paths.append(path)
        
        for path in unique_paths:
            if os.path.exists(path):
                try:
                    with open(path, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                        logger.info(f"✅ Loaded data from {path} ({len(data)} items)")
                        return data
                except json.JSONDecodeError as e:
                    logger.error(f"❌ JSON decode error in {path}: {e}")
                    continue
                except Exception as e:
                    logger.error(f"❌ Error loading from {path}: {e}")
                    continue
        
        logger.error(f"❌ Could not load {file_path} from any path")
        return []
    
    def search_dataset(self, dataset: List[Dict], query: str, search_fields: List[str]) -> List[Dict]:
        """Enhanced search with better scoring and relevance"""
        if not dataset:
            logger.warning(f"⚠️ Dataset is empty for {self.name}")
            return []
            
        results = []
        query_lower = query.lower()
        # Remove common stop words
        stop_words = {'what', 'is', 'are', 'am', 'was', 'were', 'be', 'been', 'being', 
                      'the', 'a', 'an', 'of', 'to', 'for', 'with', 'on', 'at', 'from',
                      'by', 'in', 'as', 'into', 'through', 'during', 'including',
                      'who', 'whom', 'whose', 'which', 'that', 'why', 'how', 'where',
                      'when', 'does', 'do', 'did', 'has', 'have', 'had', 'will', 'would',
                      'could', 'should', 'may', 'might', 'must', 'allah', 'quran'}
        
        query_words = [w for w in query_lower.split() if len(w) > 2 and w not in stop_words]
        
        for item in dataset:
            score = 0
            matched_fields = []
            
            for field in search_fields:
                if field in item:
                    field_value = str(item[field]).lower()
                    
                    # Exact phrase match (highest score)
                    if query_lower in field_value:
                        score += 10
                        matched_fields.append(field)
                    
                    # Field contains the whole query phrase
                    if len(query_lower) > 3 and query_lower in field_value:
                        score += 8
                        matched_fields.append(field)
                    
                    # Individual word matches with weights
                    for word in query_words:
                        if word in field_value:
                            # Check if word appears as a standalone term
                            if re.search(r'\b' + re.escape(word) + r'\b', field_value):
                                score += 3
                            else:
                                score += 1
                            if field not in matched_fields:
                                matched_fields.append(field)
                    
                    # Check for related terms (common Islamic terms)
                    related_terms = {
                        'allah': ['god', 'lord', 'divine', 'creator'],
                        'prophet': ['muhammad', 'messenger', 'rasul'],
                        'prayer': ['salah', 'namaz', 'dua', 'supplication'],
                        'fasting': ['sawm', 'ramadan'],
                        'charity': ['zakat', 'sadaqah', 'giving'],
                        'patience': ['sabr', 'steadfast', 'perseverance'],
                        'mercy': ['rahmah', 'compassion', 'kindness'],
                        'forgiveness': ['maghfirah', 'pardon', 'repentance'],
                        'heaven': ['jannah', 'paradise', 'garden'],
                        'hell': ['jahannam', 'fire', 'punishment'],
                    }
                    
                    for word in query_words:
                        if word in related_terms:
                            for related in related_terms[word]:
                                if related in field_value:
                                    score += 2
                                    if field not in matched_fields:
                                        matched_fields.append(field)
            
            # Boost score for surah names that match
            if item.get('surah_name') and any(w in item['surah_name'].lower() for w in query_words):
                score += 5
            
            if score > 0:
                item['_match_score'] = score
                item['_matched_fields'] = list(set(matched_fields))
                results.append(item)
        
        # Sort by score (higher is better)
        results.sort(key=lambda x: x.get('_match_score', 0), reverse=True)
        return results[:5]
    
    def format_citations(self, response: Dict) -> Dict:
        """Add citations to response"""
        if 'citations' not in response:
            response['citations'] = []
        
        if response.get('citations'):
            citation_text = "\n\n📚 **Sources & References:**\n"
            seen = set()
            for i, citation in enumerate(response['citations'], 1):
                if citation.get('source'):
                    key = f"{citation.get('source')}-{citation.get('reference', '')}"
                    if key not in seen:
                        seen.add(key)
                        citation_text += f"{i}. {citation['source']}"
                        if citation.get('reference'):
                            citation_text += f" - {citation['reference']}"
                        citation_text += "\n"
            response['text'] += citation_text
        
        return response