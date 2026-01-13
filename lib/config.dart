// ==========================
// Vidyakunj Server Config
// ==========================
//
// IMPORTANT:
// - AUTH & SMS use SMS server
// - ATTENDANCE & SUMMARY use Backend server
// - Do NOT add "/" at end of URLs
//

/// 🔐 AUTH + SMS SERVER
const String AUTH_SERVER_URL =
    "https://vidyakunj-sms-server.onrender.com";

/// 📊 ATTENDANCE + SUMMARY SERVER
const String DATA_SERVER_URL =
    "https://vidyakunj-backend.onrender.com";

/// 🧪 LOCAL BACKEND (optional)
// const String AUTH_SERVER_URL = "http://localhost:3000";
// const String DATA_SERVER_URL = "http://localhost:10000";
