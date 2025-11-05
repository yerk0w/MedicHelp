require("dotenv").config();
const mongoose = require('mongoose');
const express = require('express');
const cors = require('cors');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('./User/User')

const app = express();
const PORT = process.env.PORT || 5001;
const MONGO_URI = process.env.MONGO_URI;
const JWT_SECRET = process.env.JWT_SECRET;

if (!MONGO_URI) {
    console.error("ОШИБКА: MONGO_URI не установлен в .env файле");
    process.exit(1);
}
if (!JWT_SECRET) {
    console.error("ОШИБКА: JWT_SECRET не установлен в .env файле");
    process.exit(1);
}

mongoose.connect(MONGO_URI)
.then(() => console.log("MongoDB connected"))
.catch((err) => {
    console.log("MongoDB connection error:", err);
    process.exit(1);
});

app.use(cors());
app.use(express.json());

const validateEmail = (email) => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
};

const validatePassword = (password) => {
    return password && password.length >= 6;
};

app.post("/api/register", async (req, res) => {
    try {
        const { name, email, password } = req.body;
        
        if (!name || !email || !password) {
            return res.status(400).json({ message: "Пожалуйста заполните все поля" });
        }
        
        if (!validateEmail(email)) {
            return res.status(400).json({ message: "Неверный формат email" });
        }
        
        if (!validatePassword(password)) {
            return res.status(400).json({ message: "Пароль должен содержать минимум 6 символов" });
        }
        
        if (name.trim().length < 2) {
            return res.status(400).json({ message: "Имя должно содержать минимум 2 символа" });
        }
        
        const existingUser = await User.findOne({ email: email.toLowerCase() });
        if (existingUser) {
            return res.status(400).json({ message: "Пользователь с таким email уже существует" });
        }
        
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);
        const newUser = new User({
            name: name.trim(),
            email: email.toLowerCase(),
            password: hashedPassword,
            registeredAt: new Date(),
        });
        const savedUser = await newUser.save();
        res.status(201).json({ message: "Пользователь успешно зарегистрирован", userId: savedUser._id });
    } catch (error) {
        console.error("Ошибка при регистрации пользователя:", error);
        res.status(500).json({ message: "Ошибка сервера" });
    }
});

app.post ("/api/login", async (req, res) => {
    try {
        const { email, password } = req.body;
        if (!email || !password) {
            return res.status(400).json({ message: "Пожалуйста заполните все поля" });
        }
        
        const normalizedEmail = email.toLowerCase();
        
        const user = await User.findOne({ email: normalizedEmail });
        if (!user) {
            return res.status(400).json({ message: "Неверный email или пароль" });
        }
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(400).json({ message: "Неверный email или пароль" });
        }
        const payload = {
            user: {
                id: user.id
            }
        };
        jwt.sign(
            payload,
            process.env.JWT_SECRET,
            { expiresIn: '30d' },
            (err, token) => {
                if (err) throw err;
                res.status(200).json({
                    token: token,
                    name: user.name,
                    email: user.email
                });
            }
        );
    } catch (error) {
        console.error("Ошибка при входе пользователя:", error);
        res.status(500).json({ message: "Ошибка сервера" });
    }
});

app.post("/api/forgot-password", async (req, res) => {
    try {
        const { email } = req.body;
        
        if (!email) {
            return res.status(400).json({ message: "Пожалуйста, введите email" });
        }
        
        const user = await User.findOne({ email: email.toLowerCase() });
        if (!user) {
            // Не раскрываем информацию о существовании пользователя
            return res.status(200).json({ 
                message: "Если аккаунт с таким email существует, инструкции по восстановлению пароля отправлены" 
            });
        }
        
        // В реальном приложении здесь был бы код отправки email
        // Для демо просто возвращаем успех
        const resetToken = jwt.sign(
            { userId: user._id },
            process.env.JWT_SECRET,
            { expiresIn: '1h' }
        );
        
        console.log(`Reset token for ${email}: ${resetToken}`);
        
        res.status(200).json({ 
            message: "Если аккаунт с таким email существует, инструкции по восстановлению пароля отправлены",
            // Только для демо - в продакшене токен отправляется на email
            demoToken: resetToken 
        });
    } catch (error) {
        console.error("Ошибка при восстановлении пароля:", error);
        res.status(500).json({ message: "Ошибка сервера" });
    }
});

// Сброс пароля
app.post("/api/reset-password", async (req, res) => {
    try {
        const { token, newPassword } = req.body;
        
        if (!token || !newPassword) {
            return res.status(400).json({ message: "Недостаточно данных" });
        }
        
        if (!validatePassword(newPassword)) {
            return res.status(400).json({ message: "Пароль должен содержать минимум 6 символов" });
        }
        
        try {
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            const user = await User.findById(decoded.userId);
            
            if (!user) {
                return res.status(404).json({ message: "Пользователь не найден" });
            }
            
            const salt = await bcrypt.genSalt(10);
            user.password = await bcrypt.hash(newPassword, salt);
            await user.save();
            
            res.status(200).json({ message: "Пароль успешно изменен" });
        } catch (err) {
            return res.status(401).json({ message: "Неверный или истекший токен" });
        }
    } catch (error) {
        console.error("Ошибка при сбросе пароля:", error);
        res.status(500).json({ message: "Ошибка сервера" });
    }
});

app.use('/api/entries', require('./routes/entries'));
app.use('/api/profile', require('./routes/profile'));
app.use('/api/analytics', require('./routes/analytics'));
app.use("/api/courses", require("./routes/courses"));
app.use("/api/report", require("./routes/report"));
app.use("/api/insight", require("./routes/insight"));

app.listen(PORT, () => console.log(`server run on port ${PORT}`));
