const jwt = require('jsonwebtoken');
require('dotenv').config();

module.exports = function(req, res, next) {
    const token = req.header('Authorization');
    if (!token) {
        return res.status(401).json({ message: 'Нет токена, авторизация отклонена' });
    }
    
    const tokenString = token.split(' ')[1];

    if (!tokenString) {
        return res.status(401).json({ message: 'Неверный формат токена' });
    }

    try {
        const decoded = jwt.verify(tokenString, process.env.JWT_SECRET);
        req.user = decoded.user;
        next();
    } catch (err) {
        res.status(401).json({ message: 'Токен недействителен' });
    }
};