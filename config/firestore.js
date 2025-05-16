import { initializeApp, cert, getApps } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

import env from 'dotenv'
env.config()
// Ambil service account dari ENV atau dari file lokal
const serviceAccountStr = Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT, 'base64').toString();
const serviceAccount = JSON.parse(serviceAccountStr);

// Cegah inisialisasi ulang
if (!getApps().length) {
  initializeApp({
    credential: cert(serviceAccount),
  });
}

const db = getFirestore();
export default db;
