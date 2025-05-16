import { google } from "googleapis";
import stream from 'stream';

// Tidak perlu import fs karena tidak membaca file fisik lagi

const SCOPES = ["https://www.googleapis.com/auth/drive.file"];

const authenticateDrive = async () => {
    try {
        // Mengambil service account key dari variabel lingkungan Base64
        const serviceAccountBase64 = process.env.FIREBASE_SERVICE_ACCOUNT;
        
        // Jika tidak ada di env, maka gunakan fallback ke file (untuk development)
        let credentials;
        
        if (serviceAccountBase64) {
            // Mendekode Base64 dan parse JSON
            const serviceAccountStr = Buffer.from(serviceAccountBase64, 'base64').toString();
            credentials = JSON.parse(serviceAccountStr);
        } else {
            // Fallback ke file untuk development
            // Perhatikan: Ini hanya digunakan jika tidak ada env variable
            // Import fs secara dinamis hanya jika diperlukan
            const { promises: fs } = await import('fs');
            const credentialsJson = await fs.readFile("serviceAccountKey.json", 'utf-8');
            credentials = JSON.parse(credentialsJson);
        }

        const auth = new google.auth.GoogleAuth({
            credentials,
            scopes: SCOPES
        });
        
        const drive = google.drive({ version: 'v3', auth });
        return drive;
    } catch (error) {
        console.error("Error authenticating with Google Drive:", error);
        throw new Error("Failed to authenticate with Google Drive");
    }
}

export const uploadFileToDrive = async (buffer, fileName) => {
    try {
        const drive = await authenticateDrive();
        const bufferStream = new stream.PassThrough();
        bufferStream.end(buffer);

        const fileMetadata = {
            name: fileName,
            parents: [process.env.GOOGLE_DRIVE_FOLDER_ID],
        };

        const media = {
            mimeType: "image/png",
            body: bufferStream
        };

        const response = await drive.files.create({
            resource: fileMetadata,
            media: media,
            fields: "id, webViewLink",
        });
        
        await drive.permissions.create({
            fileId: response.data.id,
            requestBody: {
                role: 'reader',
                type: 'anyone',
            },
        });
        
        console.log("📂 Drive Link:", response.data.webViewLink);
        return response.data.webViewLink;
    } catch (err) {
        console.error("Error uploading to Google Drive:", err);
        throw new Error('Failed uploading file to Google Drive');
    }
}