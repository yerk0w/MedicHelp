const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");
const HealthEntry = require("../User/HealthEntry");
const { GoogleGenerativeAI } = require("@google/generative-ai");

const googleApiKey = process.env.GOOGLE_API_KEY;
const genAI = googleApiKey ? new GoogleGenerativeAI(googleApiKey) : null;

const MS_IN_DAY = 24 * 60 * 60 * 1000;

const toDayKey = (value) => {
  const date = new Date(value);
  date.setHours(0, 0, 0, 0);
  return date.getTime();
};

const extractAdherenceSummary = (entry) => {
  if (!entry) {
    return { total: 0, taken: 0 };
  }

  let total = 0;
  let taken = 0;

  if (Array.isArray(entry.medicationsTaken) && entry.medicationsTaken.length) {
    total = entry.medicationsTaken.length;
    taken = entry.medicationsTaken.filter(
      (med) => med.status === "taken"
    ).length;
  }

  if (
    total === 0 &&
    Array.isArray(entry.medications) &&
    entry.medications.length
  ) {
    total = entry.medications.length;
    taken = entry.medications.filter((med) => med.taken === true).length;
  }

  return { total, taken };
};

const calculateAdherenceStreak = (entries) => {
  let streak = 0;
  let previousDayKey = null;

  for (const entry of entries) {
    if (!entry) continue;

    const dayKey = toDayKey(entry.entryDate);
    const adherence = extractAdherenceSummary(entry);
    const allTaken =
      adherence.total > 0 && adherence.taken === adherence.total;

    if (!allTaken) {
      break;
    }

    if (previousDayKey === null) {
      streak = 1;
      previousDayKey = dayKey;
      continue;
    }

    const diffDays = Math.round((previousDayKey - dayKey) / MS_IN_DAY);

    if (diffDays === 0) {
      continue;
    }

    if (diffDays === 1) {
      streak += 1;
      previousDayKey = dayKey;
      continue;
    }

    break;
  }

  return streak;
};

const collectTags = (entries, keys) => {
  const unique = new Set();

  entries.forEach((entry) => {
    keys.forEach((key) => {
      const value = entry?.[key];
      if (Array.isArray(value)) {
        value
          .filter((tag) => typeof tag === "string" && tag.trim().length)
          .forEach((tag) => unique.add(tag.trim()));
      }
    });
  });

  return Array.from(unique).slice(0, 6);
};

const sanitizeAiText = (text) =>
  text
    .replace(/\*\*/g, "")
    .replace(/\*/g, "")
    .replace(/[#`]/g, "")
    .replace(/\s+/g, " ")
    .trim();

const pluralizeDays = (count) => {
  const mod10 = count % 10;
  const mod100 = count % 100;

  if (mod10 === 1 && mod100 !== 11) {
    return `${count} день`;
  }

  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return `${count} дня`;
  }

  return `${count} дней`;
};

const fallbackMotivation = (streakDays) => {
  if (streakDays >= 3) {
    return `Отличная работа! Вы уже ${pluralizeDays(
      streakDays
    )} подряд придерживаетесь курса лечения. Продолжайте в том же духе.`;
  }

  if (streakDays >= 1) {
    return `Вы уже ${pluralizeDays(
      streakDays
    )} отмечаете прием лекарств без пропусков. Еще немного — и это станет прочной привычкой.`;
  }

  return "Сделайте запись вместе с врачом сегодня и отметьте прием лекарств — это поможет удерживать прогресс.";
};

const truncate = (text, max) => {
  if (!text) return "";
  return text.length > max ? `${text.slice(0, max)}…` : text;
};

router.get("/today", auth, async (req, res) => {
  try {
    const recentEntries = await HealthEntry.find({
      userId: req.user.id,
    })
      .sort({ entryDate: -1 })
      .limit(7)
      .lean();

    if (!recentEntries || recentEntries.length === 0) {
      return res.status(200).json({
        healthFact:
          "Интересный факт: регулярные записи самочувствия помогают врачу точнее корректировать лечение и поддерживать пациента.",
        motivation:
          "Создайте первую запись вместе с врачом, чтобы получать персональные рекомендации и мотивацию.",
        hasEntryToday: false,
        streakDays: 0,
      });
    }

    const todayKey = toDayKey(new Date());
    const todayEntry =
      recentEntries.find((entry) => toDayKey(entry.entryDate) === todayKey) ||
      null;
    const latestEntry = todayEntry ?? recentEntries[0];

    const entryContext = {
      symptoms: collectTags([latestEntry], ["symptomTags", "symptoms"]),
      lifestyle: collectTags([latestEntry], ["lifestyleTags"]),
      notes: truncate((latestEntry?.notes || "").trim(), 280),
    };

    const aggregatedSymptoms = collectTags(recentEntries, [
      "symptomTags",
      "symptoms",
    ]);
    const aggregatedLifestyle = collectTags(recentEntries, ["lifestyleTags"]);

    const adherenceSummary = extractAdherenceSummary(latestEntry);
    const streakDays = calculateAdherenceStreak(recentEntries);
    const hasEntryToday = Boolean(todayEntry);

    let healthFact =
      "Интересный факт: регулярное выполнение рекомендаций врача и ведение заметок помогают заметно улучшать результаты лечения.";
    let motivation = fallbackMotivation(streakDays);

    if (!genAI) {
      return res.status(200).json({
        healthFact,
        motivation,
        hasEntryToday,
        streakDays,
      });
    }

    const model = genAI.getGenerativeModel({
      model: "gemini-2.5-flash-lite",
    });

    const factPrompt = `
Ты — "Компас Здоровья", ассистент врача в клинике.
Нужно дать один короткий (до 2 предложений) интересный факт или полезный совет о здоровье.
Учитывай данные пациента: ${JSON.stringify({
      todaySymptoms: entryContext.symptoms,
      todayLifestyle: entryContext.lifestyle,
      todayNotes: entryContext.notes,
      frequentSymptoms: aggregatedSymptoms,
      frequentLifestyle: aggregatedLifestyle,
    })}
Помни, что человек проходит курс лечения и отмечает самочувствие в приложении.
Ответ на русском языке, без списков, Markdown, эмодзи и обращения по имени.
`;

    const motivationPrompt = `
Ты — мотивационный наставник для пациента клиники.
Сформулируй короткое (1-2 предложения) сообщение поддержки на русском языке.
Используй данные: ${JSON.stringify({
      streakDays,
      hasEntryToday,
      medicationsPlanned: adherenceSummary.total,
      medicationsTaken: adherenceSummary.taken,
      lastEntryDate:
        latestEntry.entryDate instanceof Date
          ? latestEntry.entryDate.toISOString()
          : latestEntry.entryDate,
      lifestyleTags: entryContext.lifestyle,
    })}
Если streakDays >= 3 — похвали за серию и предложи держать темп.
Если streakDays == 0 — мягко мотивируй сделать запись и принять лекарства сегодня.
Без Markdown, эмодзи и перечислений.
`;

    try {
      const [factGeneration, motivationGeneration] = await Promise.all([
        model.generateContent(factPrompt),
        model.generateContent(motivationPrompt),
      ]);

      const factResponse = await factGeneration.response;
      const motivationResponse = await motivationGeneration.response;

      const factText = sanitizeAiText(factResponse.text());
      const motivationText = sanitizeAiText(motivationResponse.text());

      if (factText) {
        healthFact = factText;
      }

      if (motivationText) {
        motivation = motivationText;
      }
    } catch (aiError) {
      console.error("AI generation error in /api/insight/today:", aiError);
    }

    res.status(200).json({
      healthFact,
      motivation,
      hasEntryToday,
      streakDays,
    });
  } catch (err) {
    console.error("ОШИБКА в /api/insight/today:", err.message);
    res.status(500).send("Ошибка сервера при генерации инсайта");
  }
});

module.exports = router;
