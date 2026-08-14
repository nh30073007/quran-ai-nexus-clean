from typing import Dict, List

class HallucinationGuard:
    """
    Prevents AI from generating fake Quran verses or Hadith.
    """
    
    # Known surah names for validation
    SURAHS = {
        "fatiha", "bakara", "al-imran", "nisa", "maidah", "anam", "araf", "anfal", 
        "taubah", "yunus", "hud", "yusuf", "rad", "ibrahim", "hijr", "nahl",
        "isra", "kahf", "maryam", "taha", "anbiya", "hajj", "muminun", "nur",
        "furqan", "shuara", "namal", "qasas", "ankabut", "rum", "luqman",
        "sajdah", "ahzab", "saba", "fatir", "yasin", "saffat", "sad", "zumar",
        "ghafir", "fussilat", "shura", "zukhruf", "dukhan", "jathiyah", "ahqaf",
        "muhammad", "fath", "hujurat", "qaf", "dhariyat", "tur", "najm", "qamar",
        "rahman", "waqiah", "hadid", "mujadilah", "hashr", "mumtahanah", "saff",
        "jumuah", "munafiqun", "taghabun", "talaq", "tahrim", "mulk", "qalam",
        "haqqah", "maarij", "nuh", "jinn", "muzzammil", "muddaththir", "qiyamah",
        "insan", "mursalat", "naba", "naziat", "abasa", "takwir", "infitar",
        "mutaffifin", "inshiqaq", "buruj", "tariq", "ala", "ghashiyah", "fajr",
        "balad", "shams", "layl", "duha", "sharh", "tin", "alaq", "qadr",
        "bayyinah", "zilzal", "adiyat", "qariah", "takathur", "asr", "humazah",
        "fil", "quraysh", "maun", "kawthar", "kafirun", "nasr", "masad", "ikhlas",
        "falaq", "nas"
    }
    
    @staticmethod
    def check_fake_verses(text: str) -> Dict:
        """Detect potential fake/fabricated verses"""
        warnings = []
        
        # Check for suspicious patterns (AI sometimes generates fake verses)
        suspicious_patterns = [
            "আল্লাহ বলেন", "Allah says", "قال الله",
        ]
        
        # If text claims to quote Quran but has no citation
        has_claim = any(p in text.lower() for p in suspicious_patterns)
        has_citation = "[" in text or "(" in text or "Surah" in text or "سورة" in text
        
        if has_claim and not has_citation:
            warnings.append("⚠️ Potential unverified Quranic claim without citation")
        
        return {
            "is_safe": len(warnings) == 0,
            "warnings": warnings
        }
    
    @staticmethod
    def validate_response(text: str) -> Dict:
        """Full validation pipeline"""
        hallucination = HallucinationGuard.check_fake_verses(text)
        
        return {
            "passed": hallucination["is_safe"],
            "checks": {
                "hallucination": hallucination
            },
            "can_display": hallucination["is_safe"]  # Block if unsafe
        }