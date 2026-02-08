.pragma library

var RECITERS = [
  {
    id: "curated:alafasy",
    providerId: 7,
    name: "Mishary Rashid Alafasy",
    language: "ar",
    styleTags: ["murattal", "balanced"],
    audioTemplate: "https://everyayah.com/data/Alafasy_128kbps/{ayahKey}.mp3",
    source: "curated"
  },
  {
    id: "curated:husary",
    providerId: 5,
    name: "Mahmoud Khalil Al-Husary",
    language: "ar",
    styleTags: ["murattal", "clear"],
    audioTemplate: "https://everyayah.com/data/Husary_128kbps/{ayahKey}.mp3",
    source: "curated"
  },
  {
    id: "curated:minshawy",
    providerId: 6,
    name: "Muhammad Siddiq Al-Minshawi",
    language: "ar",
    styleTags: ["murattal", "slow"],
    audioTemplate: "https://everyayah.com/data/Minshawy_Murattal_128kbps/{ayahKey}.mp3",
    source: "curated"
  },
  {
    id: "curated:abdulbasit",
    providerId: 1,
    name: "Abdul Basit Abdus Samad",
    language: "ar",
    styleTags: ["murattal", "rich"],
    audioTemplate: "https://everyayah.com/data/Abdul_Basit_Murattal_192kbps/{ayahKey}.mp3",
    source: "curated"
  },
  {
    id: "curated:sudais",
    providerId: 3,
    name: "Abdurrahman As-Sudais",
    language: "ar",
    styleTags: ["haram", "clear"],
    audioTemplate: "https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/{ayahKey}.mp3",
    source: "curated"
  },
  {
    id: "curated:shuraym",
    providerId: 4,
    name: "Saud Ash-Shuraym",
    language: "ar",
    styleTags: ["haram", "firm"],
    audioTemplate: "https://everyayah.com/data/Saood_ash-Shuraym_128kbps/{ayahKey}.mp3",
    source: "curated"
  },
  {
    id: "curated:ayyoub",
    providerId: 11,
    name: "Muhammad Ayyoub",
    language: "ar",
    styleTags: ["warm", "murattal"],
    audioTemplate: "https://everyayah.com/data/Muhammad_Ayyoub_128kbps/{ayahKey}.mp3",
    source: "curated"
  },
  {
    id: "curated:hudhaify",
    providerId: 12,
    name: "Ali Al-Hudhaify",
    language: "ar",
    styleTags: ["calm", "murattal"],
    audioTemplate: "https://everyayah.com/data/Hudhaify_128kbps/{ayahKey}.mp3",
    source: "curated"
  },
  {
    id: "curated:ghamdi",
    providerId: 13,
    name: "Saad Al-Ghamdi",
    language: "ar",
    styleTags: ["smooth", "murattal"],
    audioTemplate: "https://everyayah.com/data/Ghamadi_40kbps/{ayahKey}.mp3",
    source: "curated"
  },
  {
    id: "curated:maher",
    providerId: 2,
    name: "Maher Al Muaiqly",
    language: "ar",
    styleTags: ["balanced", "murattal"],
    audioTemplate: "https://everyayah.com/data/Maher_AlMuaiqly_64kbps/{ayahKey}.mp3",
    source: "curated"
  }
];

function list() {
  return RECITERS.slice();
}

function byId(id) {
  for (var i = 0; i < RECITERS.length; i += 1) {
    if (RECITERS[i].id === id) {
      return RECITERS[i];
    }
  }
  return null;
}
