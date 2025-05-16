import { getTransporter } from "../config/emails.js";
import env from 'dotenv';
import db from '../config/firestore.js';
import axios from 'axios';

if (process.env.NODE_ENV !== 'production') {
  env.config();
}

// Send email notification + Add new connection
export const handleAddedConnection = async (req, res) => {
  const { uid, to, from } = req.body;
  if (!uid || !to || !from) {
    return res.status(400).json({ error: "Missing required fields." });
  }

  try {
    const connRef = db.collection('users').doc(uid).collection('connection');
    const connDoc = await connRef.get();
    const connectionsCount = connDoc.size;

    if (connectionsCount >= 3) {
      return res.status(500).json({ message: "Reached maximum number of connections" });
    }

    const isConn = await connRef.where('to', '==', to).get();
    if (!isConn.empty) {
      return res.status(500).json({ message: "Email already added in your connection" });
    }

    try {
      await sendEmailNotificationForConnection(to, from);
    } catch (emailErr) {
      console.error("Error sending email:", emailErr);
      return res.status(500).json({ message: "Failed to send email." });
    }

    await connRef.doc().set({
      to,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    });

    return res.status(200).json({ message: "Connection added and email sent." });
  } catch (err) {
    console.error("Error in handleAddedConnection:", err);
    return res.status(500).json({ message: "Failed to add connection or send email." });
  }
};

// Delete connection
export const handleDeleteConnection = async (req, res) => {
  const { uid, toEmail } = req.body;
  if (!uid || !toEmail) {
    return res.status(400).json({ error: "Missing required fields." });
  }

  try {
    const conn = await db
      .collection('users')
      .doc(uid)
      .collection('connection')
      .where('to', '==', toEmail)
      .get();

    if (conn.empty) {
      return res.status(404).json({ message: "No matching connection found" });
    }

    const deletionPromises = conn.docs.map(doc => doc.ref.delete());

    await Promise.all(deletionPromises);

    return res.status(200).json({ message: "Connection deleted" });
  } catch (err) {
    console.error("Error in handleDeleteConnection:", err);
    return res.status(500).json({ message: "Failed to delete connection" });
  }
};

// Get list of connections
export const getListOfConnection = async (req, res) => {
  try {
    const { uid } = req.body;

    if (!uid) return res.status(401).json({ error: "UID is required" });

    const usersSnapshot = await db.collection("users").doc(uid).collection("connection").get();

    if (usersSnapshot.empty) {
      return res.status(404).json({ error: "No connections found" });
    }

    const emailList = usersSnapshot.docs.map(doc => ({ email: doc.data().to }));

    return res.status(200).json(emailList);
  } catch (error) {
    console.error("Error getting connections:", error);
    return res.status(500).json({ error: "Internal server error" });
  }
};

// Find friends via Gmail
export const findFriendsByGmail = async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer')) {
      return res.status(401).json({ message: 'Unauthorized: Token not provided' });
    }

    const accessToken = authHeader.split(' ')[1];

    const googleResponse = await axios.get('https://people.googleapis.com/v1/people/me/connections', {
      params: {
        personFields: 'names,emailAddresses',
      },
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    });

    res.json(googleResponse.data.connections);
  } catch (err) {
    console.error("Error accessing Gmail contacts:", err);
    res.status(500).json({ message: err.response?.data || err.message });
  }
};

// Send email notification
const sendEmailNotificationForConnection = async (to, from) => {
  try {
    const transporter = await getTransporter();

    const mailOptions = {
      from: `OhMyGerd <${process.env.EMAIL_ADMIN}>`,
      to,
      subject: `${from} has added you to be their connection.`,
      html: `<h2>${from} has added you to be their connection.</h2>`
    };

    const result = await transporter.sendMail(mailOptions);
    console.log(`Berhasil mengirim email ke ${to}`);
    return result;
  } catch (err) {
    console.error("Error in sendEmailNotificationForConnection:", err);
    throw err; // Biarkan error dilempar ke atas agar bisa ditangani di try-catch luar
  }
};
