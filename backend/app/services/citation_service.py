from typing import List, Dict, Optional
import re

class CitationExtractor:
    """
    Extracts and validates citations from AI responses.
    Every AI response MUST have traceable sources.
    """
    
    QURAN_PATTERN = r'(سورة?\s+\w+|Surah\s+\w+|সূরা\s+\w+)\s*[:：]?\s*(\d+)(?:\s*[-–]\s*(\d+))?'
    HADITH_PATTERN = r'(Bukhari|Muslim|Tirmidhi|Abu\s+Dawud|Nasai|Ibn\s+Majah)\s*(\d+):?(\d+)?'
    
    @staticmethod
    def extract_quran_refs(text: str) -> List[Dict]:
        """Extract Quran references from text"""
        refs = []
        matches = re.finditer(CitationExtractor.QURAN_PATTERN, text, re.IGNORECASE)
        for match in matches:
            refs.append({
                "type": "quran",
                "surah": match.group(1),
                "ayah": match.group(2),
                "range_end": match.group(3),
                "raw": match.group(0)
            })
        return refs
    
    @staticmethod
    def extract_hadith_refs(text: str) -> List[Dict]:
        """Extract Hadith references"""
        refs = []
        matches = re.finditer(CitationExtractor.HADITH_PATTERN, text, re.IGNORECASE)
        for match in matches:
            refs.append({
                "type": "hadith",
                "book": match.group(1),
                "number": match.group(2),
                "raw": match.group(0)
            })
        return refs
    
    @staticmethod
    def validate_citations(text: str, min_required: int = 1) -> Dict:
        """
        Validates that AI response has proper citations.
        Returns validation report.
        """
        quran_refs = CitationExtractor.extract_quran_refs(text)
        hadith_refs = CitationExtractor.extract_hadith_refs(text)
        
        total_refs = len(quran_refs) + len(hadith_refs)
        
        return {
            "is_valid": total_refs >= min_required,
            "quran_refs": quran_refs,
            "hadith_refs": hadith_refs,
            "total_refs": total_refs,
            "confidence_score": min(1.0, total_refs * 0.3 + 0.4),  # More refs = higher confidence
            "warning": None if total_refs >= min_required else "No citations found. Response may be unreliable."
        }

# Global instance
citation_extractor = CitationExtractor()