from sentence_transformers import SentenceTransformer
import numpy as np
import faiss
import json
import os
import pickle
import logging
from typing import List, Dict, Any, Optional

logger = logging.getLogger(__name__)

class QuranEmbeddingService:
    """Service for semantic search using embeddings and FAISS"""
    
    def __init__(self):
        self.model_name = "sentence-transformers/all-MiniLM-L6-v2"
        self.model = None
        self.index = None
        self.verses = []
        self.embeddings = []
        self.cache_dir = "data/cache"
        self.index_path = "data/cache/quran_faiss.index"
        self.metadata_path = "data/cache/quran_metadata.pkl"
        self.confidence_threshold = 0.2  # Lowered threshold
        
        os.makedirs(self.cache_dir, exist_ok=True)
        
        self._load_model()
        self._load_or_build_index()
        
        logger.info("✅ QuranEmbeddingService initialized")
    
    def _load_model(self):
        try:
            self.model = SentenceTransformer(self.model_name)
            logger.info(f"✅ Loaded embedding model: {self.model_name}")
        except Exception as e:
            logger.error(f"❌ Failed to load model: {e}")
            raise
    
    def _load_or_build_index(self):
        if os.path.exists(self.index_path) and os.path.exists(self.metadata_path):
            try:
                self.index = faiss.read_index(self.index_path)
                with open(self.metadata_path, 'rb') as f:
                    self.verses = pickle.load(f)
                logger.info(f"✅ Loaded FAISS index with {len(self.verses)} verses from cache")
                return
            except Exception as e:
                logger.warning(f"⚠️ Failed to load cached index: {e}")
        
        self._build_index()
    
    def _build_index(self):
        from app.agents.tafsir_agent import TafsirAgent
        
        logger.info("🔨 Building FAISS index...")
        
        agent = TafsirAgent()
        verses = agent.quran_data
        
        if not verses:
            logger.error("❌ No Quran data available")
            return
        
        # Prepare texts for embedding
        texts = []
        for verse in verses:
            text = f"""
            Surah: {verse.get('surah_name', 'Unknown')}
            Verse: {verse.get('verse_number', '?')}
            Translation: {verse.get('translation_en', '')}
            Tafsir Ibn Kathir: {verse.get('tafsir', {}).get('ibn_kathir', '')}
            Tafsir Jalalayn: {verse.get('tafsir', {}).get('jalalayn', '')}
            Sufi Rumi: {verse.get('sufi', {}).get('rumi', '')}
            Sufi Ibn Arabi: {verse.get('sufi', {}).get('ibn_arabi', '')}
            """.strip()
            texts.append(text)
            self.verses.append(verse)
        
        logger.info(f"🔄 Generating embeddings for {len(texts)} verses...")
        embeddings = self.model.encode(texts, show_progress_bar=True)
        self.embeddings = embeddings
        
        dimension = embeddings.shape[1]
        self.index = faiss.IndexFlatL2(dimension)
        self.index.add(embeddings.astype('float32'))
        
        faiss.write_index(self.index, self.index_path)
        with open(self.metadata_path, 'wb') as f:
            pickle.dump(self.verses, f)
        
        logger.info(f"✅ Built FAISS index with {len(self.verses)} verses")
    
    def search(self, query: str, top_k: int = 5) -> List[Dict[str, Any]]:
        if not self.model or not self.index:
            logger.error("❌ Model or index not loaded")
            return []
        
        try:
            query_embedding = self.model.encode([query])
            query_embedding = query_embedding.astype('float32')
            
            distances, indices = self.index.search(query_embedding, top_k)
            
            results = []
            for i, idx in enumerate(indices[0]):
                if idx < len(self.verses):
                    verse = self.verses[idx].copy()
                    # Convert L2 distance to similarity score (0-1 range)
                    # Lower distance = higher similarity
                    similarity = float(1.0 / (1.0 + distances[0][i]))
                    verse['_score'] = similarity
                    verse['_distance'] = float(distances[0][i])
                    results.append(verse)
            
            return results
            
        except Exception as e:
            logger.error(f"❌ Search error: {e}")
            return []
    
    def search_with_fallback(self, query: str, top_k: int = 5) -> List[Dict[str, Any]]:
        """Search with semantic first, fallback to keyword"""
        results = self.search(query, top_k)
        
        # If semantic search gives decent results, return them
        if results and results[0].get('_score', 0) > 0.15:
            logger.info(f"✅ Semantic search found results (score: {results[0].get('_score', 0):.2f})")
            return results
        
        # Fallback to keyword search
        logger.info("🔄 Using keyword search fallback")
        from app.agents.tafsir_agent import TafsirAgent
        agent = TafsirAgent()
        keyword_results = agent.search_dataset(
            agent.quran_data, 
            query, 
            ['translation_en', 'surah_name', 'text_arabic']
        )
        
        # Convert to same format with scores
        formatted_results = []
        for i, r in enumerate(keyword_results):
            r['_score'] = max(0.2, 1.0 - (i * 0.15))
            formatted_results.append(r)
        
        return formatted_results