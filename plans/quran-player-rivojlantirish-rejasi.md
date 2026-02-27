# Quran Player rivojlantirish rejasi

Ushbu hujjat `kde-widget-quran` loyihasini tahlil qilish natijalari va uni rivojlantirish bo'yicha batafsil rejani o'z ichiga oladi.

## 1. Joriy holat tahlili

Loyiha KDE Plasma 6 uchun yozilgan audio-pleyer vidjeti (plasmoid) hisoblanadi.

*   **Texnologiyalar:** QML, QtQuick, JavaScript (mantiq uchun), C++ (MPRIS uchun).
*   **Audio manba:** Quran.com API v4.
*   **Hozirgi imkoniyatlar:**
    *   Sura va oyat diapazonini tanlash.
    *   To'liq surani tinglash.
    *   Tanlangan qorilar ro'yxati.
    *   MPRIS (media tugmalar) qo'llab-quvvatlash.
    *   A-B takrorlash va uyqu taymeri.
*   **Kamchiliklar:**
    *   **Keshlash yo'q:** Audio har safar internetdan yuklanadi.
    *   **Matn yo'q:** Oyat matni va tarjimasi ko'rsatilmaydi.
    *   **Qidiruv yo'q:** Suralarni faqat raqam bo'yicha tanlash mumkin.
    *   **Offline rejim:** Internet bo'lmasa ishlamaydi.

## 2. Rivojlantirish bosqichlari

Loyiha murakkabligini hisobga olib, ishlarni 3 ta asosiy bosqichga bo'lishni taklif qilaman.

### Bosqich 1: UI/UX yaxshilash va Qidiruv (Quick Wins)
Bu bosqichda kodga katta o'zgartirish kiritmasdan foydalanuvchi tajribasi yaxshilanadi.

*   **Vazifa 1.1: Sura qidiruv tizimi.**
    *   *Muammo:* Suralar ro'yxati uzun (114 ta), topish qiyin.
    *   *Yechim:* `RangePicker.qml` va boshqa joylarda sura tanlash menyusiga qidiruv qatorini (SearchField) qo'shish. `SurahMeta.js` dagi `nameEn` va `nameAr` bo'yicha filtratsiya qilish.
*   **Vazifa 1.2: Xatolarni aniqroq ko'rsatish.**
    *   *Muammo:* Internet yo'qligida yoki API xatoligida foydalanuvchiga tushunarsiz xabar chiqishi mumkin.
    *   *Yechim:* `ProviderQuranCom.js` da xatolarni aniqroq ushlash va `DesktopExpanded.qml` dagi status panelida "Internetni tekshiring" kabi aniq maslahatlar berish.
*   **Vazifa 1.3: UI jilolash.**
    *   Progress bar animatsiyalarini silliqlash.
    *   Shrift o'lchamlarini moslashtirish (ba'zi joylarda kichik ko'rinishi mumkin).

### Bosqich 2: Matn va Tarjimalar (Eng muhim funksiya)
Foydalanuvchi nafaqat tinglashi, balki o'qishi ham kerak.

*   **Vazifa 2.1: API so'rovini kengaytirish.**
    *   `ProviderQuranCom.js` dagi so'rovlarga `fields=text_uthmani,text_indopak` va `translations=...` parametrlarini qo'shish.
    *   *Eslatma:* Audio bilan birga matnni ham sinxron yuklash kerak.
*   **Vazifa 2.2: Yangi UI rejimi "O'qish rejimi" (Lyrics View).**
    *   `DesktopExpanded.qml` da "Player" sahifasiga yangi ko'rinish qo'shish.
    *   Hozirgi o'qilayotgan oyat matnini katta qilib ko'rsatish.
    *   Tarjimalarni tanlash imkoniyati (Sozlamalar bo'limida).

### Bosqich 3: Optimizatsiya va Offline rejim (Murakkab)
Bu bosqich loyihani to'laqonli mustaqil dasturga aylantiradi.

*   **Vazifa 3.1: Keshlash tizimi (Caching).**
    *   `Storage.js` yoki yangi C++ moduli orqali yuklangan audio fayllarni mahalliy diskda (`~/.local/share/plasma/plasmoids/...`) saqlash.
    *   Keyingi safar internetga murojaat qilmasdan lokal faylni o'qish.
*   **Vazifa 3.2: Yuklab olish menejeri (Download Manager).**
    *   "Butun surani yuklab olish" tugmasini qo'shish.
    *   Yuklash jarayonini (progress) ko'rsatish.

## 3. Texnik tafsilotlar va takliflar

### Kod strukturasi bo'yicha:
*   **JS -> C++ migratsiyasi (Kelajak uchun):** Hozirgi JS logikasi (`ProviderQuranCom.js`) yetarli, lekin offline rejim va fayl tizimi bilan ishlash uchun C++ (Qt Network & LocalStorage) xavfsizroq va tezroq bo'ladi. Hozircha JS bilan davom etish mumkin.
*   **QML Modullari:** `Components` papkasidagi fayllar yaxshi ajratilgan. Yangi funksiyalar (masalan, Matn ko'rish) uchun `contents/ui/components/AyahTextDisplay.qml` kabi yangi komponent yaratish kerak.

### Tavsiya etilgan ketma-ketlik:

1.  **Qidiruv funksiyasini qo'shish** (Eng oson va tez natija).
2.  **Matn ko'rsatish funksiyasini qo'shish** (Eng ko'p so'raladigan funksiya).
3.  **Keshlashni implementatsiya qilish** (Barqarorlik uchun).

## 4. Xulosa

Loyiha asosi juda mustahkam. Kod toza va yaxshi tashkil etilgan. Eng katta kamchilik - matnning yo'qligi va faqat onlayn ishlashidir. Rejadagi 2-bosqich eng yuqori prioritetga ega bo'lishi kerak.
