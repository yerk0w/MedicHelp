// back/routes/insight.js

const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");
const HealthEntry = require("../User/HealthEntry");
const { GoogleGenerativeAI } = require("@google/generative-ai");

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY);

router.get("/today", auth, async (req, res) => {
  try {
    const entries = await HealthEntry.find({ userId: req.user.id })
      .sort({ entryDate: -1 })
      .limit(7);

    if (entries.length === 0) {
      return res.status(200).json({
        text: "Начните вести записи, чтобы получать персонализированные инсайты!",
      });
    }

    // Проверка достижений
    const achievement = checkAchievements(entries);

    let prompt;

    if (achievement) {
      // Промпт для достижений
      prompt = `
Ты — мотивирующий ИИ-ассистент в медицинском приложении.
Пользователь достиг важной цели: ${achievement}

Дай ОДИН короткий мотивирующий комплимент (максимум 2 предложения).

Правила:
- Позитивный и вдохновляющий тон
- Максимум 2 предложения
- На русском языке
- Без вступлений, только поздравление
- Упомяни достижение

Примеры:
"Отличная работа! 3 дня подряд записей — вы серьезно относитесь к своему здоровью."
"Потрясающе! Вы принимали лекарства вовремя всю неделю. Такая дисциплина приносит результаты!"
      `;
    } else {
      // Промпт для интересных фактов
      const dataForContext = entries.slice(0, 3).map((entry) => ({
        symptoms: entry.symptomTags || [],
        lifestyle: entry.lifestyleTags || [],
      }));

      prompt = `
Ты — ИИ-ассистент в медицинском приложении.
Дай ОДИН интересный факт о здоровье (максимум 2-3 предложения).

Контекст пользователя (для релевантности):
${JSON.stringify(dataForContext)}

Правила:
- Интересный научный факт о здоровье, питании, сне или образе жизни
- Максимум 2-3 предложения
- На русском языке
- Без вступлений, только сам факт
- Практичный и полезный
- Если в контексте есть стресс/сон/кофе — дай факт об этом

Примеры хороших фактов:
"Знали ли вы? 30 минут прогулки на свежем воздухе снижают уровень стресса на 40%."
"Вода за 30 минут до еды помогает организму лучше усваивать витамины и минералы."
"Качество сна улучшается, если за 2 часа до сна избегать яркого света экранов."
"Регулярное потребление воды уменьшает частоту головных болей на 30-50%."
      `;
    }

    const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash-exp" });
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const insightText = response.text().trim();

    res.status(200).json({ text: insightText });
  } catch (err) {
    console.error(err.message);
    res.status(500).json({
      text: "Пейте больше воды — это улучшает самочувствие и концентрацию!",
    });
  }
});

function checkAchievements(entries) {
  if (entries.length < 3) return null;

  // Достижение: 3 дня подряд записей
  const last3Days = entries.slice(0, 3);
  const dates = last3Days.map((e) => e.entryDate.toDateString());
  const uniqueDates = new Set(dates);

  if (uniqueDates.size >= 3) {
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    const twoDaysAgo = new Date(today);
    twoDaysAgo.setDate(twoDaysAgo.getDate() - 2);

    const recentDates = [
      today.toDateString(),
      yesterday.toDateString(),
      twoDaysAgo.toDateString(),
    ];

    const hasStreak = recentDates.every((date) => dates.includes(date));
    if (hasStreak) {
      return "3 дня подряд ведения записей";
    }
  }

  // Достижение: 7 записей за неделю
  if (entries.length >= 7) {
    return "7 записей за неделю";
  }

  // Достижение: хорошее соблюдение режима приема лекарств
  const last7Days = entries.slice(0, 7);
  let totalMeds = 0;
  let takenMeds = 0;

  last7Days.forEach((entry) => {
    if (entry.medicationsTaken && entry.medicationsTaken.length > 0) {
      totalMeds += entry.medicationsTaken.length;
      takenMeds += entry.medicationsTaken.filter(
        (m) => m.status === "taken"
      ).length;
    }
  });

  if (totalMeds >= 10 && takenMeds / totalMeds >= 0.9) {
    return "отличное соблюдение режима приема лекарств (90%+)";
  }

  // Достижение: снижение уровня симптомов
  if (entries.length >= 5) {
    const recent = entries.slice(0, 3);
    const older = entries.slice(3, 6);

    const recentAvg =
      recent.reduce((sum, e) => sum + (e.headacheLevel || 0), 0) /
      recent.length;
    const olderAvg =
      older.reduce((sum, e) => sum + (e.headacheLevel || 0), 0) / older.length;

    if (olderAvg > 0 && recentAvg < olderAvg * 0.7) {
      return "значительное снижение уровня симптомов за последние дни";
    }
  }

  return null;
}

module.exports = router;
