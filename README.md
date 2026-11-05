# 🚩 वर्गणी कलेक्शन (Vargani Collection)
### संपूर्ण मंडळ व्यवस्थापन व वर्गणी संकलन ॲप्लिकेशन (Complete Mandal Management App)

उत्सव मंडळे, गणेशोत्सव, नवरात्रोत्सव, शिवजयंती, दहीहंडी आणि सामाजिक संस्थांसाठी तयार केलेले आधुनिक, पारदर्शक आणि संपूर्ण डिजिटल वित्तीय व्यवस्थापन ॲप्लिकेशन.

---

## 🚀 मुख्य वैशिष्ट्ये (Key Features)

1. **अखंड बहु-मंडळ व्यवस्थापन (Multi-Mandal Architecture):**
   - एकाच लॉगिनमधून अनेक मंडळांचा कारभार सांभाळा.
   - मंडळाचा स्वतंत्र युनिक आयडी व ६-अंकी आमंत्रण कोड (उदा. `VG2026A`).
   - मंडळांमध्ये सहजपणे स्विच करा (Switch Mandal) — एका मंडळाचा हिशेब दुसऱ्या मंडळात कधीही मिसळणार नाही.

2. **कुटुंब व सदस्य व्यवस्थापन (Family & Member Management):**
   - कुटुंबांची नोंदणी, कुटुंब प्रमुखाचे नाव, घर नंबर, पत्ता व संपर्क.
   - कुटुंबातील व्यक्तींची (सदस्यांची) स्वतंत्र नोंदणी व वय/लिंग तपशील.
   - सुरक्षित दप्तरबंद (Safe Archival) सुविधा.

3. **डायनॅमिक वर्गणी आकारणी (Vargani Configuration):**
   - प्रति सदस्य वर्गणी (उदा. ₹५०० × ४ सदस्य = ₹२,०००).
   - प्रति कुटुंब निश्चित वर्गणी (Fixed Family Amount).
   - सवलत (Discount) व विशेष देणगी (Special Contribution) पर्याय.

4. **डिजिटल वर्गणी पावती व WhatsApp शेअरिंग (Receipt & WhatsApp Sharing):**
   - रोख (Cash), UPI (GPay/PhonePe/Paytm), बँक ट्रान्सफर द्वारे वर्गणी नोंदणी.
   - स्वयंचलित युनिक पावती क्र. (`RCT-2026-XXXX`) व व्यवहार क्र. (`TXN-2026-XXXX`).
   - एका क्लिकवर कुटुंब प्रमुखाला WhatsApp वर पावती संदेश पाठवा.
   - अधिकृत PDF पावती जनरेशन व प्रिंटिंग सुविधा.

5. **ठेव विनंती व मंजुरी कार्यप्रणाली (Strict Deposit & Approval System):**
   - कार्यकर्त्यांनी गोळा केलेली रक्कम खजिनदाराकडे जमा करण्यासाठी **ठेव विनंती (Deposit Request)** तयार करणे.
   - केवळ अधिकृत नियुक्त खजिनदारच ती रक्कम स्वीकारू किंवा नाकारू शकतो.
   - सुरक्षित डेटाबेस लेव्हल रो-लॉकिंग (Atomic Row-Level Locking) मुळे दुहेरी जमा होणे अशक्य.

6. **खर्च व्यवस्थापन (Expense Management):**
   - मंडप, साऊंड सिस्टिम, लाईट, अन्नदान, वाहतूक, वीज इत्यादी कॅटेगरीनुसार खर्चाची नोंद.
   - कोणी खर्च केला आणि कोणाला दिला याची स्पष्ट नोंद.

7. **थेट आर्थिक डॅशबोर्ड व ताळेबंद अहवाल (Financial Dashboard & Reports):**
   - एकूण अपेक्षित वर्गणी, गोळा झालेली रक्कम, येणे बाकी रक्कम.
   - खजिनदाराकडे जमा रक्कम व अंतिम शिल्लक (Available Balance).
   - सर्व वर्गणी व खर्चाच्या नोंदी **Excel (.xlsx)** स्वरूपात एका क्लिकवर डाउनलोड करा.

---

## 🛠️ तंत्रज्ञान (Tech Stack)

- **Frontend:** Flutter (v3.47+), Dart (v3.13+), Material Design 3
- **State Management:** Riverpod (`flutter_riverpod`)
- **Navigation:** GoRouter (`go_router`)
- **Backend:** Supabase, PostgreSQL, Row Level Security (RLS)
- **Exports:** PDF (`pdf`, `printing`), Excel (`excel`), WhatsApp Sharing (`url_launcher`, `share_plus`)

---

## ⚙️ Supabase डेटाबेस सेटअप (2-Min Setup)

१. [Supabase Dashboard](https://supabase.com/dashboard) मध्ये जाऊन नवीन प्रोजेक्ट तयार करा.
२. डाव्या बाजूच्या मेनूमधून **SQL Editor** उघडा.
३. या प्रोजेक्टमधील `supabase/schema.sql` फाईलमधील संपूर्ण कोड कॉपी करा आणि SQL Editor मध्ये पेस्ट करून **Run** वर क्लिक करा.
   - सर्व आवश्यक टेबल्स, फॉरेन कीज, ट्रिगर्स, रो-लेव्हल सिक्युरिटी (RLS) पॉलिसीज आणि अटोमिक अप्रूव्हल फंक्शन्स आपोआप तयार होतील.
४. Supabase डॅशबोर्डवरील **Project Settings -> API** मध्ये जा.
५. तुमच्या प्रोजेक्टमधील `.env` फाईल उघडा आणि खालील माहिती भरा:
```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=sb_publishable_szI_G_sLgUsqWgs_60iaPQ_HpO0r3RV
```

---

## 📱 ॲप चालवण्यासाठी (Run Application)

```bash
# १. डिपेंडन्सीज मिळवा
flutter pub get

# २. ॲप चालवा (Android / iOS / Web / Windows)
flutter run
```

---
*© 2026 Vargani Collection — संपूर्ण सुरक्षित, पारदर्शक आणि डिजिटल मंडळ व्यवस्थापन.*
