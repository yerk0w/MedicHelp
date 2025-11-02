const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const User = require('../User/User');

// GET /api/profile
// Получить данные профиля пользователя
router.get('/', auth, async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select('-password');
        if (!user) {
            return res.status(404).json({ message: 'Пользователь не найден' });
        }
        res.json({
            name: user.name,
            email: user.email,
            medicalCard: user.medicalCard
        });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Ошибка сервера');
    }
});

// PUT /api/profile
// Обновить медкарту пользователя
router.put('/', auth, async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        if (!user) {
            return res.status(404).json({ message: 'Пользователь не найден' });
        }

        user.medicalCard = req.body;

        await user.save();
        res.status(200).json(user.medicalCard);

    } catch (err) {
        console.error(err.message);
        res.status(500).send('Ошибка сервера');
    }
});

module.exports = router;