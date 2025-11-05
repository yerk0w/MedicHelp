// back/routes/analytics.js - обновить модель на более быструю

const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");
const HealthEntry = require("../User/HealthEntry");
const { GoogleGenerativeAI } = require("@google/generative-ai");

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY);

router.get("/", auth, async (req, res) => {
  try {
    const entries = await HealthEntry.find({ userId: req.user.id }).sort({
      entryDate: 1,
    });

    if (entries.length < 3) {
      return res.status(200).json({
        insights:
          "Недостаточно данных для анализа. Пожалуйста, добавьте хотя бы 3 записи о своем самочувствии.",
      });
    }

    const dataForAI = entries.map((entry) => ({
      date: entry.entryDate,
      headache: entry.headacheLevel,
      meds: entry.medications?.filter((m) => m.taken).map((m) => m.name) || [],
      symptoms: entry.symptomTags || [],
      lifestyle: entry.lifestyleTags || [],
      notes: entry.notes,
    }));

    const prompt = `
      Ты — "Компас Здоровья", ИИ-ассистент в медицинском приложении.
      Твоя задача — проанализировать JSON-данные о здоровье пользователя и найти 3-4 ключевые корреляции или вывода.

      Вот данные пользователя:
      ${JSON.stringify(dataForAI)}

      Найди интересные связи, например:
      - "Лекарство -> Симптом" (например, "Прием Ибупрофена снижает головную боль...")
      - "Образ жизни -> Симптом" (например, "Плохой сон коррелирует с усталостью...")
      - "Триггеры" (например, "Кофе после 16:00 связан с головной болью...")
      
      Твой ответ должен быть на русском языке.
      Ответь только списком из 3-4 пунктов. Не пиши вступлений типа "Вот ваш анализ".
      Начинай каждый пункт со знака '• '.
    `;

    const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash-exp" });
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const aiInsights = response.text();

    res.status(200).json({ insights: aiInsights });
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Ошибка сервера при генерации аналитики");
  }
});

module.exports = router;
