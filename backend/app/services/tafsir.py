from typing import Dict, Optional

class TafsirService:
    def get_tafsir(self, verse_data: Dict, language: str = "en") -> str:
        if 'tafsir' in verse_data and verse_data['tafsir']:
            if language == "bn":
                return self._get_bangla_tafsir(verse_data)
            return self._get_english_tafsir(verse_data)
        
        return self._generate_contextual_tafsir(verse_data, language)
    
    def _get_english_tafsir(self, verse_data: Dict) -> str:
        tafsir = verse_data.get('tafsir', {})
        response = "**Ibn Kathir Tafsir:**\n"
        response += tafsir.get('ibn_kathir', 'Tafsir not available') + "\n\n"
        response += "**Al-Jalalayn Tafsir:**\n"
        response += tafsir.get('jalalayn', 'Tafsir not available')
        
        if 'sufi' in verse_data and verse_data['sufi']:
            sufi = verse_data['sufi']
            response += "\n\n**Sufi Insights:**\n"
            response += f"**Rumi:** {sufi.get('rumi', '')}\n"
            response += f"**Ibn Arabi:** {sufi.get('ibn_arabi', '')}"
        
        return response
    
    def _get_bangla_tafsir(self, verse_data: Dict) -> str:
        tafsir = verse_data.get('tafsir', {})
        response = "**ইবনে কাসির তাফসীর:**\n"
        response += tafsir.get('ibn_kathir', 'তাফসীর পাওয়া যায়নি') + "\n\n"
        response += "**জালালাইন তাফসীর:**\n"
        response += tafsir.get('jalalayn', 'তাফসীর পাওয়া যায়নি')
        
        if 'sufi' in verse_data and verse_data['sufi']:
            sufi = verse_data['sufi']
            response += "\n\n**সূফী দর্শন:**\n"
            response += f"**রুমি:** {sufi.get('rumi', '')}\n"
            response += f"**ইবনে আরাবী:** {sufi.get('ibn_arabi', '')}"
        
        return response
    
    def _generate_contextual_tafsir(self, verse_data: Dict, language: str = "en") -> str:
        translation = verse_data.get('translation_en', '')
        verse_lower = translation.lower()
        
        themes = []
        if any(word in verse_lower for word in ['mercy', 'merciful']):
            themes.append('mercy')
        if any(word in verse_lower for word in ['fear', 'punishment']):
            themes.append('warning')
        if any(word in verse_lower for word in ['patience', 'persevere']):
            themes.append('patience')
        if any(word in verse_lower for word in ['prayer', 'worship']):
            themes.append('worship')
        
        if language == "bn":
            return self._generate_bangla_contextual_tafsir(verse_data, themes)
        return self._generate_english_contextual_tafsir(verse_data, themes)
    
    def _generate_english_contextual_tafsir(self, verse_data: Dict, themes: list) -> str:
        response = f"**Tafsir of {verse_data.get('reference', '')}:**\n\n"
        response += f"This verse from Surah {verse_data.get('surah_name', '')} teaches us about "
        response += f"{', '.join(themes[:3]) if themes else 'divine wisdom'}.\n\n"
        
        response += "**Practical Application:**\n"
        if 'mercy' in themes:
            response += "• Remember Allah's mercy in your daily life\n"
        if 'patience' in themes:
            response += "• Practice patience during difficulties\n"
        if 'worship' in themes:
            response += "• Increase your acts of worship\n"
        if 'warning' in themes:
            response += "• Seek Allah's forgiveness and guidance\n"
        
        if not themes:
            response += "• Reflect on the deeper meaning of this verse\n"
        
        response += "\n**Spiritual Benefit:**\n"
        response += "Reflecting on this verse strengthens faith and guides towards righteous actions."
        
        return response
    
    def _generate_bangla_contextual_tafsir(self, verse_data: Dict, themes: list) -> str:
        theme_translations = {
            'mercy': 'রহমত',
            'warning': 'সতর্কবাণী',
            'patience': 'ধৈর্য',
            'worship': 'ইবাদত'
        }
        bangla_themes = [theme_translations.get(t, t) for t in themes]
        
        response = f"**{verse_data.get('reference', '')} এর তাফসীর:**\n\n"
        response += f"সূরা {verse_data.get('surah_name', '')} এর এই আয়াতটি শিক্ষা দেয় "
        response += f"{', '.join(bangla_themes[:3]) if themes else 'ঐশী প্রজ্ঞা'} সম্পর্কে।\n\n"
        
        response += "**ব্যবহারিক প্রয়োগ:**\n"
        if 'mercy' in themes:
            response += "• দৈনন্দিন জীবনে আল্লাহর রহমত স্মরণ করুন\n"
        if 'patience' in themes:
            response += "• কঠিন সময়ে ধৈর্য ধারণ করুন\n"
        if 'worship' in themes:
            response += "• আপনার ইবাদত বৃদ্ধি করুন\n"
        if 'warning' in themes:
            response += "• আল্লাহর কাছে ক্ষমা ও হিদায়াত চান\n"
        
        if not themes:
            response += "• এই আয়াতের গভীর অর্থ নিয়ে চিন্তা করুন\n"
        
        response += "\n**আধ্যাত্মিক উপকারিতা:**\n"
        response += "এই আয়াত নিয়ে চিন্তা করলে ঈমান শক্তিশালী হয় এবং সৎকর্মের দিকে পথনির্দেশ করে।"
        
        return response