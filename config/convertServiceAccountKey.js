
import fs  from 'fs';
import { readFileSync } from "fs";

const serviceAccount = JSON.parse(
  readFileSync(new URL("../serviceAccountKey.json", import.meta.url))
);
// // Ubah ke string satu baris (menghapus whitespace yang tidak perlu)
// const singleLineJSON = JSON.stringify(serviceAccount);

// // Simpan ke file baru
// fs.writeFileSync('serviceAccountKey-single-line.json', singleLineJSON);

// console.log('File serviceAccountKey-single-line.json berhasil dibuat');
// console.log('Gunakan string berikut untuk variabel lingkungan Vercel:');
// console.log(singleLineJSON);

const serviceAccountBase64 = Buffer.from(JSON.stringify(serviceAccount)).toString('base64');
console.log('\nAtau gunakan format Base64 berikut:');
console.log(serviceAccountBase64);