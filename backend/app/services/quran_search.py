import json
import os
import numpy as np
import pandas as pd
import faiss
import joblib
from rank_bm25 import BM25Okapi
from sentence_transformers import SentenceTransformer
from typing import List, Dict, Optional

class QuranSearchService:
    def __init__(self):
        self.cache_dir = "cache"
        os.makedirs(self.cache_dir, exist_ok=True)
        
        self.df = self._load_data()
        self.model = self._load_model()
        self._build_hybrid_index()
    
    def _load_data(self):
        possible_paths = [
            "data/quran_en1.json",
            "../data/quran_en1.json",
            "quran_en1.json"
        ]
        
        for path in possible_paths:
            if os.path.exists(path):
                with open(path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                df = pd.DataFrame(data)
                if 'surah_number' in df.columns and 'verse_number' in df.columns:
                    df['reference'] = df['surah_number'].astype(str) + ':' + df['verse_number'].astype(str)
                df['text'] = df['text_arabic'] + ' ' + df['translation_en']
                return df
        
        return self._create_sample_data()
    
    def _load_model(self):
        try:
            return SentenceTransformer('all-MiniLM-L6-v2')
        except:
            return None
    
    def _create_sample_data(self):
        data = {
            'ayah_id': list(range(1, 11)),
            'surah_number': [1, 1, 1, 1, 1, 2, 2, 2, 2, 2],
            'surah_name': ['Al-Fatiha'] * 5 + ['Al-Baqarah'] * 5,
            'verse_number': [1, 2, 3, 4, 5, 255, 256, 257, 258, 259],
            'text_arabic': [
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
                'الرَّحْمَٰنِ الرَّحِيمِ',
                'مَالِكِ يَوْمِ الدِّينِ',
                'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
                'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ',
                'لَا إِكْرَاهَ فِي الدِّينِ',
                'اللَّهُ وَلِيُّ الَّذِينَ آمَنُوا',
                'الَّذِينَ يُؤْمِنُونَ بِالْغَيْبِ',
                'أُولَٰئِكَ عَلَىٰ هُدًى مِنْ رَبِّهِمْ'
            ],
            'translation_en': [
                'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
                '[All] praise is [due] to Allah, Lord of the worlds.',
                'The Entirely Merciful, the Especially Merciful.',
                'Sovereign of the Day of Recompense.',
                'It is You we worship and You we ask for help.',
                'Allah - there is no deity except Him, the Ever-Living, the Sustainer of existence.',
                'There is no compulsion in religion.',
                'Allah is the ally of those who believe.',
                'Who believe in the unseen.',
                'Those are upon guidance from their Lord.'
            ],
            'tafsir': [
                {'ibn_kathir': 'This verse opens every Surah...', 'jalalayn': 'I begin with the Name of Allah.'},
                {'ibn_kathir': 'All praise belongs to Allah alone.', 'jalalayn': 'All praise is for Allah.'},
                {'ibn_kathir': 'Allah is described with two attributes of mercy.', 'jalalayn': 'The Merciful, the Compassionate.'},
                {'ibn_kathir': 'Allah is the Master of the Day of Judgment.', 'jalalayn': 'Owner of the Day of Recompense.'},
                {'ibn_kathir': 'We worship Allah alone.', 'jalalayn': 'You alone we worship.'},
                {'ibn_kathir': 'The greatest verse in the Quran.', 'jalalayn': 'Allah, no god but Him.'},
                {'ibn_kathir': 'Islam cannot be forced.', 'jalalayn': 'No compulsion in religion.'},
                {'ibn_kathir': 'Allah protects the believers.', 'jalalayn': 'Allah is the ally of believers.'},
                {'ibn_kathir': 'Belief in unseen is part of faith.', 'jalalayn': 'Who believe in the unseen.'},
                {'ibn_kathir': 'These are the guided ones.', 'jalalayn': 'They are on guidance.'}
            ]
        }
        df = pd.DataFrame(data)
        df['reference'] = df['surah_number'].astype(str) + ':' + df['verse_number'].astype(str)
        df['text'] = df['text_arabic'] + ' ' + df['translation_en']
        return df
    
    def _build_hybrid_index(self):
        """Build hybrid index: FAISS + BM25 with caching"""
        cache_file = os.path.join(self.cache_dir, "hybrid_index.pkl")
        
        if os.path.exists(cache_file):
            data = joblib.load(cache_file)
            self.index = data['faiss']
            self.bm25 = data['bm25']
            print("✅ Loaded hybrid index from cache! (20x faster)")
            return
        
        if self.model is None or self.df is None:
            self.index = None
            self.bm25 = None
            return
        
        texts = self.df['text'].tolist()
        
        # FAISS Index
        embeddings = self.model.encode(texts, show_progress_bar=False)
        dim = embeddings.shape[1]
        self.index = faiss.IndexFlatL2(dim)
        self.index.add(np.array(embeddings))
        
        # BM25 Index
        tokenized = [text.split() for text in texts]
        self.bm25 = BM25Okapi(tokenized)
        
        # Cache
        joblib.dump({
            'faiss': self.index,
            'bm25': self.bm25,
            'df': self.df
        }, cache_file)
        print("✅ Hybrid index built and cached!")
    
    def search(self, query: str, surah_filter: Optional[int] = None, top_k: int = 5) -> List[Dict]:
        """Hybrid search: FAISS (60%) + BM25 (40%)"""
        if self.model is None or self.index is None or self.bm25 is None:
            return self.fallback_search(query, surah_filter, top_k)
        
        try:
            # FAISS
            q_emb = self.model.encode([query], show_progress_bar=False)
            distances, indices = self.index.search(q_emb, top_k * 3)
            
            # BM25
            bm25_scores = self.bm25.get_scores(query.split())
            bm25_indices = sorted(range(len(bm25_scores)), 
                                 key=lambda i: bm25_scores[i], reverse=True)[:top_k * 3]
            
            # Combine scores
            combined_scores = {}
            
            for i, idx in enumerate(indices[0]):
                if idx < len(self.df):
                    score = (1 - distances[0][i] / (max(distances[0]) + 1e-10)) * 0.6
                    combined_scores[idx] = combined_scores.get(idx, 0) + score
            
            for idx in bm25_indices:
                if idx < len(self.df):
                    score = (bm25_scores[idx] / (max(bm25_scores) + 1e-10)) * 0.4
                    combined_scores[idx] = combined_scores.get(idx, 0) + score
            
            # Sort and filter
            sorted_indices = sorted(combined_scores.keys(), 
                                   key=lambda x: combined_scores[x], reverse=True)[:top_k]
            
            results = []
            for idx in sorted_indices:
                if idx < len(self.df):
                    verse = self.df.iloc[idx].to_dict()
                    if surah_filter is None or verse['surah_number'] == surah_filter:
                        verse['relevance_score'] = combined_scores[idx]
                        results.append(verse)
            
            if not results:
                return self.fallback_search(query, surah_filter, top_k)
            
            return results[:top_k]
            
        except Exception as e:
            print(f"Hybrid search error: {e}")
            return self.fallback_search(query, surah_filter, top_k)
    
    def fallback_search(self, query: str, surah_filter: Optional[int] = None, top_k: int = 5) -> List[Dict]:
        """Fallback search if hybrid fails"""
        query_lower = query.lower()
        results = []
        
        for idx, row in self.df.iterrows():
            if surah_filter is not None and row['surah_number'] != surah_filter:
                continue
            
            score = 0
            text_arabic = str(row.get('text_arabic', '')).lower()
            translation = str(row.get('translation_en', '')).lower()
            
            if query_lower in text_arabic:
                score += 5
            if query_lower in translation:
                score += 4
            
            query_words = query_lower.split()
            for word in query_words:
                if len(word) > 2:
                    if word in text_arabic:
                        score += 2
                    if word in translation:
                        score += 1.5
            
            if score > 0:
                max_possible = 12 + len([w for w in query_words if len(w) > 2]) * 3.5
                normalized_score = min(score / max_possible, 1.0) if max_possible > 0 else 0.5
                results.append({**row.to_dict(), 'relevance_score': float(normalized_score)})
        
        results.sort(key=lambda x: x['relevance_score'], reverse=True)
        return results[:top_k]
    
    def get_verse_by_reference(self, reference: str) -> Optional[Dict]:
        verse = self.df[self.df['reference'] == reference]
        if not verse.empty:
            return verse.iloc[0].to_dict()
        return None