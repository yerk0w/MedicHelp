const mongoose = require("mongoose")
 
const ConnectDB = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log("монгодб косылды!")
    } catch (error) {
        console.error("монгодб қосылмады", error.message);
        process.exit(1);
    }
};

module.exports = ConnectDB