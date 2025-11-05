const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");
const HealthEntry = require("../User/HealthEntry");
const { GoogleGenerativeAI } = require("@google/generative-ai");

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY);

// GET /api/insight/today
router.get("/today", auth, async (req, res) => {
  // 👈 1. ДОБАВЛЯЕМ TRY
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const entry = await HealthEntry.findOne({
      userId: req.user.id, // 👈 2. ИСПРАВЛЕНО (было 'userId')
      entryDate: {
        $gte: today,
        $lt: tomorrow,
      },
    });

    if (!entry) {
      return res.status(200).json({
        insight:
          "Запись за сегодня еще не создана. Добавьте ее, чтобы получить инсайт.",
      });
    }

    // Если заметки пустые, не тратим вызов ИИ
    if (
      !entry.notes &&
      entry.symptomTags.length === 0 &&
      entry.lifestyleTags.length === 0
    ) {
      return res.status(200).json({
        insight:
          "Вы не добавили заметки или симптомы сегодня. AI нечего анализировать.",
      });
    }

    const dataForAI = {
      headache: entry.headacheLevel,
      meds: entry.medications?.filter((m) => m.taken).map((m) => m.name) || [],
      symptoms: entry.symptomTags || [],
      lifestyle: entry.lifestyleTags || [],
      notes: entry.notes,
    };

    const prompt = `
      Ты — "Компас Здоровья", ИИ-ассистент.
      Проанализируй одну запись пользователя за сегодня: ${JSON.stringify(
        dataForAI
      )}
      Дай ОДИН короткий (1-2 предложения) вывод или совет на основе этих данных.
      Например: "Вы отметили 'Плохой сон' и 'Усталость'. Постарайтесь сегодня лечь спать пораньше."
      Или: "Вы приняли 'Ибупрофен' при головной боли уровня ${
        dataForAI.headache
      }. Надеюсь, вам стало легче."
      
      Твой ответ должен быть на русском языке.
      Не используй форматирование (никаких '•' или '*'). Только текст.
    `;

    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" }); // Используем flash-модель для скорости
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const aiInsight = response.text();

    res.status(200).json({ insight: aiInsight });

    // 👈 3. ДОБАВЛЯЕМ CATCH
  } catch (err) {
    console.error("ОШИБКА в /api/insight/today:", err.message);
    res.status(500).send("Ошибка сервера при генерации инсайта");
  }
});

module.exports = router;
