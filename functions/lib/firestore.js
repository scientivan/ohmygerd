import functions from "firebase-functions/v1";
import admin from "firebase-admin";
// Inisialisasi hanya jika belum diinisialisasi
if (!admin.apps.length) {
    admin.initializeApp();
  }
const db = admin.firestore(); // gunakan admin.firestore() langsung
export default db;
//# sourceMappingURL=firestore.js.map