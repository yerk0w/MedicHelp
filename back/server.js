require("dotenv").config();
const mongoose = require("mongoose");
const express = require("express");
const cors = require("cors");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const User = require("./User/User");
const VerificationCode = require("./User/VerificationCode");
const {
  generateVerificationCode,
  sendPasswordResetEmail,
} = require("./utils/emailService");


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
    const { name, email, password, role } = req.body;

    if (!name || !email || !password) {
      return res
        .status(400)
        .json({ message: "Пожалуйста заполните все поля" });
    }

    if (!validateEmail(email)) {
      return res.status(400).json({ message: "Неверный формат email" });
    }

    if (!validatePassword(password)) {
      return res
        .status(400)
        .json({ message: "Пароль должен содержать минимум 6 символов" });
    }

    if (name.trim().length < 2) {
      return res
        .status(400)
        .json({ message: "Имя должно содержать минимум 2 символа" });
    }

    if (role && role !== "doctor") {
      return res
        .status(400)
        .json({ message: "Регистрация доступна только врачам клиники" });
    }

    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res
        .status(400)
        .json({ message: "Пользователь с таким email уже существует" });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);
    const newUser = new User({
      name: name.trim(),
      email: email.toLowerCase(),
      password: hashedPassword,
      role: "doctor",
    });
    const savedUser = await newUser.save();
    res.status(201).json({
      message: "Врач успешно зарегистрирован",
      userId: savedUser._id,
    });
  } catch (error) {
    console.error("Ошибка при регистрации пользователя:", error);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});

app.post("/api/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res
        .status(400)
        .json({ message: "Пожалуйста заполните все поля" });
    }

    const normalizedEmail = email.toLowerCase();

    const user = await User.findOne({ email: normalizedEmail });
    if (!user) {
      return res
        .status(400)
        .json({ message: "Неверный email или пароль" });
    }
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res
        .status(400)
        .json({ message: "Неверный email или пароль" });
    }
    const payload = {
      user: {
        id: user.id,
        role: user.role || "patient",
      },
    };
    jwt.sign(
      payload,
      process.env.JWT_SECRET,
      { expiresIn: "30d" },
      (err, token) => {
        if (err) throw err;
        res.status(200).json({
          token: token,
          name: user.name,
          email: user.email,
          userId: user._id,
          role: user.role || "patient",
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
      return res.status(400).json({ message: "Email обязателен" });
    }

    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {

      return res.json({
        message: "Если email зарегистрирован, код отправлен",
      });
    }


    const code = generateVerificationCode(); 
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);


    await VerificationCode.deleteMany({
      email: email.toLowerCase(),
      type: "password_reset",
    });


    const verificationCode = new VerificationCode({
      email: email.toLowerCase(),
      code,
      type: "password_reset",
      expiresAt,
    });

    await verificationCode.save();
    await sendPasswordResetEmail(email, code);

    res.json({
      message: "Если email зарегистрирован, код отправлен",
    });
  } catch (error) {
    console.error("Ошибка:", error);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});


app.post("/api/reset-password", async (req, res) => {
  try {
    const { email, code, newPassword } = req.body;

    if (!email || !code || !newPassword) {
      return res.status(400).json({ message: "Все поля обязательны" });
    }


    if (!validatePassword(newPassword)) { 
      return res.status(400).json({ message: "Пароль минимум 6 символов" });
    }

    const verificationCode = await VerificationCode.findOne({
      email: email.toLowerCase(),
      code,
      type: "password_reset",
      expiresAt: { $gt: new Date() },
    });

    if (!verificationCode) {
      return res.status(400).json({ message: "Неверный или истекший код" });
    }

    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return res.status(404).json({ message: "Пользователь не найден" });
    }


    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(newPassword, salt);
    await user.save();


    await VerificationCode.deleteMany({
      email: email.toLowerCase(),
      type: "password_reset",
    });

    res.json({ message: "Пароль успешно изменен" });
  } catch (error) {
    console.error("Ошибка:", error);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});


app.use('/api/entries', require('./routes/entries'));
app.use('/api/profile', require('./routes/profile'));
app.use('/api/analytics', require('./routes/analytics'));
app.use("/api/courses", require("./routes/courses"));
app.use("/api/report", require("./routes/report"));
app.use("/api/insight", require("./routes/insight"));
app.use("/api/patients", require("./routes/patients"));
app.use("/api/chat", require("./routes/chat"));

app.listen(PORT, () => console.log(`server run on port ${PORT}`));
