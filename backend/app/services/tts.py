import tempfile
import os
import re
from gtts import gTTS
import pyttsx3

class TTSService:
    def __init__(self):
        self.engine = None
        try:
            self.engine = pyttsx3.init()
        except:
            pass
    
    def speak_text(self, text: str, lang: str = 'en') -> str:
        try:
            clean_text = re.sub(r'[^\w\s\.\,\?\!]', '', text)
            
            # Determine language
            if re.search(r'[\u0600-\u06FF]', text):
                tts_lang = 'ar'
            elif re.search(r'[\u0980-\u09FF]', text):
                tts_lang = 'bn'
            else:
                tts_lang = 'en' if lang == 'en' else 'bn'
            
            # Use gTTS first
            tts = gTTS(text=clean_text[:500], lang=tts_lang, slow=False)
            temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.mp3')
            tts.save(temp_file.name)
            return temp_file.name
        except:
            # Fallback to pyttsx3
            if self.engine:
                temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.mp3')
                self.engine.save_to_file(text[:500], temp_file.name)
                self.engine.runAndWait()
                return temp_file.name
        return None