const nodemailer = require("nodemailer");

const createTransporter = () => {
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT || "587"),
    secure: process.env.SMTP_SECURE === "true",
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASSWORD,
    },
  });
};

const generateVerificationCode = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

const sendPasswordResetEmail = async (email, code) => {
  const transporter = createTransporter();

  const mailOptions = {
    from: `"MedicHelp" <${process.env.SMTP_USER}>`,
    to: email,
    subject: "Сброс пароля",
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #333;">Сброс пароля</h2>
        <p>Здравствуйте!</p>
        <p>Вы запросили сброс пароля. Ваш код подтверждения:</p>
        <div style="background-color: #f5f5f5; padding: 20px; text-align: center; font-size: 32px; font-weight: bold; letter-spacing: 5px; margin: 20px 0;">
          ${code}
        </div>
        <p>Код действителен в течение 5 минут.</p>
        <p style="color: #666; font-size: 14px;">Если вы не запрашивали сброс пароля, проигнорируйте это письмо.</p>
      </div>
    `,
  };

  await transporter.sendMail(mailOptions);
};

module.exports = {
  generateVerificationCode,
  sendPasswordResetEmail,
};
