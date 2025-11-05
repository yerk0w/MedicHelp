const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");
const User = require("../User/User");
const HealthEntry = require("../User/HealthEntry");
const TreatmentCourse = require("../User/TreatmentCourse");
const Medication = require("../User/Medication");
const { GoogleGenerativeAI } = require("@google/generative-ai");

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY);

router.get("/:courseId", auth, async (req, res) => {
  try {
    const courseId = req.params.courseId;
    const userId = req.user.id;

    // 1. Получаем пользователя и медкарту
    const user = await User.findById(userId).select("-password");
    if (!user) {
      return res.status(404).json({ message: "Пользователь не найден" });
    }

    // 2. Получаем курс лечения
    const course = await TreatmentCourse.findById(courseId);
    if (!course) {
      return res.status(404).json({ message: "Курс не найден" });
    }
    if (course.userId.toString() !== userId) {
      return res.status(403).json({ message: "Доступ запрещен" });
    }

    // 3. Получаем все записи по курсу
    const entries = await HealthEntry.find({
      userId: userId,
      courseId: courseId,
    }).sort({ entryDate: 1 });

    // 4. Получаем лекарства курса
    const medications = await Medication.find({ courseId: courseId });

    // 5. Формируем промпт для ИИ
    const medCardText = `
Медицинская карта пациента:
- ФИО: ${user.medicalCard?.fullName || "Не указано"}
- Дата рождения: ${user.medicalCard?.birthDate || "Не указано"}
- Группа крови: ${user.medicalCard?.bloodType || "Не указано"}
- Аллергии: ${user.medicalCard?.allergies || "Нет"}
- Хронические заболевания: ${user.medicalCard?.chronicDiseases || "Нет"}
        `.trim();

    const courseText = `
Курс лечения: ${course.name}
Основной симптом: ${course.mainSymptom}
Период: ${course.startDate.toLocaleDateString()} - ${
      course.endDate ? course.endDate.toLocaleDateString() : "настоящее время"
    }
        `.trim();

    const medicationsText = medications
      .map(
        (med) =>
          `- ${med.name} (${med.dosage}), расписание: ${med.schedule.join(
            ", "
          )}`
      )
      .join("\n");

    const entriesText = entries
      .map((entry) =>
        `
Дата: ${entry.entryDate.toLocaleDateString()}
Симптомы: ${entry.symptoms?.join(", ") || "Не указано"}
Уровень боли: ${entry.headacheLevel || "Не указано"}/10
Принятые лекарства: ${
          entry.medicationsTaken?.map((m) => m.status).join(", ") ||
          "Нет данных"
        }
Теги симптомов: ${entry.symptomTags?.join(", ") || "Нет"}
Образ жизни: ${entry.lifestyleTags?.join(", ") || "Нет"}
Заметки: ${entry.notes || "Нет"}
        `.trim()
      )
      .join("\n\n");

    const prompt = `
Ты — ИИ-ассистент медицинского отчета. Проанализируй данные пациента и курса лечения.

${medCardText}

${courseText}

Лекарства в курсе:
${medicationsText}

Записи пациента по дням:
${entriesText}

Твоя задача:
1. Оцени соблюдение режима приема лекарств (в процентах)
2. Опиши динамику основного симптома
3. Найди 3-4 корреляции между лекарствами/образом жизни и симптомами
4. Дай краткие рекомендации для врача

Ответь в формате JSON:
{
  "compliance": "процент соблюдения режима",
  "symptomDynamics": "описание динамики симптомов",
  "correlations": ["корреляция 1", "корреляция 2", "корреляция 3"],
  "recommendations": "краткие рекомендации"
}
        `.trim();

    // 6. Вызов ИИ
    let aiSummary = {};
    try {
      const model = genAI.getGenerativeModel({
        model: "gemini-2.5-flash-lite",
      });
      const result = await model.generateContent(prompt);
      const response = await result.response;
      const text = response.text();

      // Пытаемся распарсить JSON из ответа
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        aiSummary = JSON.parse(jsonMatch[0]);
      } else {
        aiSummary = { rawText: text };
      }
    } catch (aiError) {
      console.error("Ошибка ИИ:", aiError.message);
      aiSummary = { error: "Не удалось получить анализ ИИ" };
    }

    // 7. Статистика
    const totalMedications = entries.reduce(
      (sum, entry) => sum + (entry.medicationsTaken?.length || 0),
      0
    );
    const takenMedications = entries.reduce(
      (sum, entry) =>
        sum +
        (entry.medicationsTaken?.filter((m) => m.status === "taken").length ||
          0),
      0
    );
    const compliancePercent =
      totalMedications > 0
        ? Math.round((takenMedications / totalMedications) * 100)
        : 0;

    const symptomLevels = entries.map((e) => ({
      date: e.entryDate.toLocaleDateString(),
      level: e.headacheLevel || 0,
    }));

    const statistics = {
      compliancePercent,
      totalEntries: entries.length,
      symptomLevels,
      medicationsList: medications.map((m) => ({
        name: m.name,
        dosage: m.dosage,
        schedule: m.schedule,
      })),
    };

    // 8. Ответ
    res.status(200).json({
      statistics,
      aiSummary,
      course: {
        name: course.name,
        mainSymptom: course.mainSymptom,
        startDate: course.startDate,
        endDate: course.endDate,
      },
    });
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Ошибка сервера при генерации отчета");
  }
});

module.exports = router;
