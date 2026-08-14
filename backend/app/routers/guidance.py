from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List, Dict
from datetime import datetime
import random
from ..services.quran_search import QuranSearchService
from ..services.ai_response import AIResponseService
from ..services.tafsir import TafsirService

router = APIRouter(prefix="/guidance", tags=["guidance"])
search_service = QuranSearchService()
ai_service = AIResponseService()
tafsir_service = TafsirService()

class GuidanceRequest(BaseModel):
    topic: str
    feeling: Optional[str] = None
    language: str = "en"

class LifeGuidanceResponse(BaseModel):
    reminder: str
    hadith: str
    dua: str
    verses: List[Dict]
    practical_steps: List[str]

class DailyGuidanceResponse(BaseModel):
    date: str
    verse: Dict
    tafsir: str
    reflection: str
    dua: str

# Guidance database
GUIDANCE_DB = {
    "en": {
        "lost": {
            "reminder": "Allah says: 'And whoever fears Allah - He will make for him a way out and provide for him from where he does not expect.' (Quran 65:2-3)",
            "hadith": "The Prophet (ﷺ) said: 'Strange are the ways of a believer for there is good in every affair of his...' (Muslim)",
            "dua": "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى",
            "steps": [
                "Turn to Allah in sincere prayer and seek His guidance",
                "Recite and reflect on Quran daily, especially verses about guidance",
                "Surround yourself with righteous company who remind you of Allah",
                "Make constant dua for clarity and direction"
            ]
        },
        "empty": {
            "reminder": "Allah says: 'Verily, in the remembrance of Allah do hearts find rest.' (Quran 13:28)",
            "hadith": "The Prophet (ﷺ) said: 'Allah says: I am as My servant thinks of Me. I am with him when he remembers Me.' (Bukhari)",
            "dua": "اللَّهُمَّ إِنِّي أَسْأَلُكَ حُبَّكَ وَحُبَّ مَنْ يُحِبُّكَ",
            "steps": [
                "Increase your dhikr (remembrance of Allah)",
                "Perform voluntary prayers and acts of worship",
                "Connect with the Quran through recitation and study",
                "Seek knowledge about Allah's beautiful names and attributes"
            ]
        },
        "broken": {
            "reminder": "Allah says: 'Do not despair of Allah's mercy, for Allah forgives all sins.' (Quran 39:53)",
            "hadith": "The Prophet (ﷺ) said: 'No fatigue, nor disease, nor sorrow, nor sadness befalls a Muslim... but that Allah expiates some of his sins.' (Bukhari)",
            "dua": "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ",
            "steps": [
                "Turn to Allah with sincere repentance",
                "Seek comfort in prayer and Quran",
                "Surround yourself with supportive community",
                "Remember that trials are a means of purification"
            ]
        },
        "alone": {
            "reminder": "Allah says: 'And We are closer to him than his jugular vein.' (Quran 50:16)",
            "hadith": "The Prophet (ﷺ) said: 'Allah the Exalted says: I am with My servant when he remembers Me and his lips move making mention of Me.' (Bukhari)",
            "dua": "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْأُنْسَ بِكَ",
            "steps": [
                "Increase your connection with Allah through prayer",
                "Join the Muslim community and attend gatherings",
                "Volunteer and serve others to feel connected",
                "Remember that Allah is always with you"
            ]
        },
        "purpose": {
            "reminder": "Allah says: 'I did not create jinn and humans except to worship Me.' (Quran 51:56)",
            "hadith": "The Prophet (ﷺ) said: 'Take benefit of five before five: Your youth before your old age...' (Hakim)",
            "dua": "اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا وَعَمَلًا مُتَقَبَّلًا",
            "steps": [
                "Seek beneficial knowledge that brings you closer to Allah",
                "Perform righteous deeds with sincerity",
                "Find your unique purpose in serving Allah's creation",
                "Make every action an act of worship through intention"
            ]
        }
    },
    "bn": {
        "lost": {
            "reminder": "আল্লাহ বলেন: 'যে আল্লাহকে ভয় করে, আল্লাহ তার জন্য উত্তরণের পথ বের করে দেবেন এবং তাকে তার ধারণার বাইরে থেকে রিজিক দান করবেন।' (কুরআন ৬৫:২-৩)",
            "hadith": "নবী (ﷺ) বলেছেন: 'মুমিনের অবস্থা আশ্চর্যজনক! তার সব বিষয়েই কল্যাণ রয়েছে...' (মুসলিম)",
            "dua": "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى",
            "steps": [
                "আন্তরিক দুআর মাধ্যমে আল্লাহর কাছে হিদায়াত চাওয়া",
                "প্রতিদিন কুরআন তিলাওয়াত করা এবং বিশেষ করে হিদায়াত সম্পর্কিত আয়াত নিয়ে চিন্তা করা",
                "নিজেকে সৎ লোকদের সাথে রাখা যারা আল্লাহর কথা স্মরণ করিয়ে দেয়",
                "স্পষ্টতা এবং দিকনির্দেশনার জন্য নিয়মিত দুআ করা"
            ]
        },
        "empty": {
            "reminder": "আল্লাহ বলেন: 'নিশ্চয় আল্লাহর স্মরণেই হৃদয়সমূহ শান্তি পায়।' (কুরআন ১৩:২৮)",
            "hadith": "নবী (ﷺ) বলেছেন: 'আল্লাহ বলেন: আমি আমার বান্দার ধারণা অনুযায়ী থাকি। সে যখন আমাকে স্মরণ করে, আমি তার সাথে থাকি।' (বুখারী)",
            "dua": "اللَّهُمَّ إِنِّي أَسْأَلُكَ حُبَّكَ وَحُبَّ مَنْ يُحِبُّكَ",
            "steps": [
                "আল্লাহর যিকর (স্মরণ) বৃদ্ধি করা",
                "নফল সালাত এবং অন্যান্য ইবাদত করা",
                "তিলাওয়াত এবং অধ্যয়নের মাধ্যমে কুরআনের সাথে সংযোগ তৈরি করা",
                "আল্লাহর সুন্দর নাম ও গুণাবলী সম্পর্কে জ্ঞান অর্জন করা"
            ]
        },
        "broken": {
            "reminder": "আল্লাহ বলেন: 'আল্লাহর রহমত থেকে নিরাশ হয়ো না, নিশ্চয় আল্লাহ সব গুনাহ ক্ষমা করেন।' (কুরআন ৩৯:৫৩)",
            "hadith": "নবী (ﷺ) বলেছেন: 'কোনো ক্লান্তি, রোগ, দুঃখ, বিষণ্ণতা মুসলিমের উপর আসে না... তবে আল্লাহ এর দ্বারা তার কিছু পাপ মুছে দেন।' (বুখারী)",
            "dua": "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ",
            "steps": [
                "আন্তরিক তওবার মাধ্যমে আল্লাহর দিকে ফিরে আসা",
                "সালাত এবং কুরআনে সান্ত্বনা খোঁজা",
                "সহায়ক সম্প্রদায়ের সাথে নিজেকে রাখা",
                "মনে রাখা যে পরীক্ষা পবিত্রতার মাধ্যম"
            ]
        },
        "alone": {
            "reminder": "আল্লাহ বলেন: 'আমি তার গলার শিরা থেকে অধিক নিকটে।' (কুরআন ৫০:১৬)",
            "hadith": "নবী (ﷺ) বলেছেন: 'আল্লাহ তাআলা বলেন: আমি আমার বান্দার সাথে থাকি যখন সে আমাকে স্মরণ করে এবং তার ঠোঁট নড়ে আমার স্মরণে।' (বুখারী)",
            "dua": "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْأُنْسَ بِكَ",
            "steps": [
                "সালাতের মাধ্যমে আল্লাহর সাথে সংযোগ বৃদ্ধি করা",
                "মুসলিম সম্প্রদায়ে যোগদান করা এবং সমাবেশে অংশগ্রহণ করা",
                "অন্যদের সেবা করা",
                "মনে রাখা যে আল্লাহ সবসময় আপনার সাথে আছেন"
            ]
        },
        "purpose": {
            "reminder": "আল্লাহ বলেন: 'আমি জিন ও মানুষকে শুধুমাত্র আমার ইবাদতের জন্যই সৃষ্টি করেছি।' (কুরআন ৫১:৫৬)",
            "hadith": "নবী (ﷺ) বলেছেন: 'পাঁচটি জিনিসকে পাঁচটি জিনিসের আগে মূল্য দাও: যৌবনকে বার্ধক্যের আগে...' (হাকিম)",
            "dua": "اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا وَعَمَلًا مُتَقَبَّلًا",
            "steps": [
                "উপকারী জ্ঞান অর্জন করা যা আল্লাহর নিকটবর্তী করে",
                "আন্তরিকতার সাথে সৎকর্ম করা",
                "আল্লাহর সৃষ্টির সেবায় নিজের অনন্য উদ্দেশ্য খুঁজে বের করা",
                "নিয়্যাতের মাধ্যমে প্রতিটি কাজকে ইবাদত করা"
            ]
        }
    }
}

@router.post("/life", response_model=LifeGuidanceResponse)
async def get_life_guidance(request: GuidanceRequest):
    """Get life guidance based on topic and feeling"""
    try:
        lang = request.language
        lang_code = "bn" if lang == "bn" else "en"
        
        # Determine feeling key
        feeling_map = {
            "lost": ["lost", "confused", "directionless", "হারিয়ে", "দিশেহারা"],
            "empty": ["empty", "hollow", "void", "শূন্য", "ফাঁকা"],
            "broken": ["broken", "hurt", "damaged", "ভেঙে", "আঘাত"],
            "alone": ["alone", "lonely", "isolated", "একা", "নিঃসঙ্গ"],
            "purpose": ["purpose", "meaning", "why am i here", "লক্ষ্য", "উদ্দেশ্য"]
        }
        
        matched_feeling = "purpose"
        if request.feeling:
            feeling_lower = request.feeling.lower()
            for key, keywords in feeling_map.items():
                if any(keyword in feeling_lower for keyword in keywords):
                    matched_feeling = key
                    break
        
        # Get guidance from database
        guidance = GUIDANCE_DB[lang_code].get(matched_feeling, GUIDANCE_DB[lang_code]["purpose"])
        
        # Search for relevant verses based on feeling
        search_query = matched_feeling if lang_code == "en" else "পথনির্দেশ"
        verses = search_service.search(search_query, None, 2)
        
        # Prepare response
        response = LifeGuidanceResponse(
            reminder=guidance["reminder"],
            hadith=guidance["hadith"],
            dua=guidance["dua"],
            verses=verses,
            practical_steps=guidance["steps"]
        )
        
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error getting guidance: {str(e)}")

@router.get("/daily", response_model=DailyGuidanceResponse)
async def get_daily_guidance(language: str = "en"):
    """Get daily spiritual guidance with a verse, tafsir, and reflection"""
    try:
        lang_code = "bn" if language == "bn" else "en"
        
        # Get random verse for the day (using day of year for consistency)
        day_of_year = datetime.now().timetuple().tm_yday
        df = search_service.df
        
        if df is not None and not df.empty:
            verse_idx = day_of_year % len(df)
            verse_data = df.iloc[verse_idx].to_dict()
        else:
            # Fallback verse
            verse_data = {
                "reference": "13:28",
                "surah_name": "Ar-Ra'd",
                "text_arabic": "الَّذِينَ آمَنُوا وَتَطْمَئِنُّ قُلُوبُهُم بِذِكْرِ اللَّهِ ۗ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ",
                "translation_en": "Those who have believed and whose hearts are assured by the remembrance of Allah. Unquestionably, by the remembrance of Allah hearts are assured."
            }
        
        # Get tafsir
        tafsir = tafsir_service.get_tafsir(verse_data, lang_code)
        
        # Generate reflection based on language
        if lang_code == "bn":
            reflection = "আজকের এই আয়াতটি আমাদের মনে করিয়ে দেয় যে আল্লাহর স্মরণই হৃদয়ের প্রশান্তির উৎস। আপনার দিনটি আল্লাহর যিকর দিয়ে শুরু করুন এবং সমস্ত কাজে তাঁর স্মরণ রাখুন।"
            dua = "اللَّهُمَّ اجْعَلْنَا مِنَ الَّذِينَ يَذْكُرُونَكَ كَثِيرًا"
        else:
            reflection = "Today's verse reminds us that the remembrance of Allah is the source of peace for the heart. Begin your day with dhikr and keep Allah in your remembrance throughout all your activities."
            dua = "اللَّهُمَّ اجْعَلْنَا مِنَ الَّذِينَ يَذْكُرُونَكَ كَثِيرًا"
        
        return DailyGuidanceResponse(
            date=datetime.now().strftime("%Y-%m-%d"),
            verse=verse_data,
            tafsir=tafsir,
            reflection=reflection,
            dua=dua
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error getting daily guidance: {str(e)}")

@router.post("/custom")
async def get_custom_guidance(
    query: str,
    language: str = "en"
):
    """Get custom guidance based on user query"""
    try:
        lang_code = "bn" if language == "bn" else "en"
        
        # Search for relevant verses
        verses = search_service.search(query, None, 2)
        
        # Generate AI response
        ai_response = ai_service.generate_chat_response(query, verses, lang_code)
        
        return {
            "query": query,
            "response": ai_response,
            "verses": verses,
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error getting custom guidance: {str(e)}")

@router.get("/topics")
async def get_guidance_topics(language: str = "en"):
    """Get available guidance topics"""
    lang_code = "bn" if language == "bn" else "en"
    
    topics = {
        "en": {
            "lost": "Feeling Lost",
            "empty": "Spiritual Emptiness",
            "broken": "Broken Heart",
            "alone": "Feeling Alone",
            "purpose": "Finding Purpose"
        },
        "bn": {
            "lost": "পথ হারানো",
            "empty": "আধ্যাত্মিক শূন্যতা",
            "broken": "ভাঙা হৃদয়",
            "alone": "একাকীত্ব অনুভব",
            "purpose": "উদ্দেশ্য খোঁজা"
        }
    }
    
    return {"topics": topics[lang_code]}