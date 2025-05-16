// kurang extension .js dibelakangnya, bakal ngakibatin error
import db from '../config/firestore.js'
import { readFileSync } from "fs";

const foodRecommendation = JSON.parse(
  readFileSync(new URL("../foodRecommendation.json", import.meta.url))
);
import {uploadFileToDrive} from '../config/upload-to-drive.js'
import { scanPhotoWithGemini } from './chatBotController.js'
import {formatDate,formatTime} from "../utils/tools.js";




export const getListOfNotification = async (req, res) => {
  try {
    const { uid } = req.body;
    if (!uid) {
      return res.status(400).json({ error: "UID is required" }); // 400 lebih tepat daripada 401
    }

    const notificationHistoryRef = db
      .collection('users')
      .doc(uid)
      .collection('notification')
      .limit(15);

    const notificationHistorySnapshot = await notificationHistoryRef.get();

    if (notificationHistorySnapshot.empty) {
      return res.status(404).json({ error: "No notifications found" });
    }
    
    // title, deskripsi, jam, hari
    const notificationHistoryData = notificationHistorySnapshot.docs.map(doc => ({
      ...doc.data()
    }));


    return res.status(200).json(notificationHistoryData);

  } catch (error) {
    console.error("Error fetching notifications:", error);
    return res.status(500).json({ error: "Internal Server Error" });
  }
};

export const sendBadgeData = async (req,res) => {
  try {
    const {uid} = req.body

    if(!uid){
      return res.status(400).json('uid is missing')
    }
    const badges = {
      10: '10Badge',
      30: '30Badge',
      100: '100Badge',
      300: '300Badge',
      500: '500Badge'
    };

    try{
      const userRef = await db.collection("users").doc(uid).get();
      const userData = userRef.data()

      const badgeStatus = {}
      for (const key in badges){
        const badgeKey = `is${key}Badge`
        badgeStatus[badgeKey] = userData[badgeKey] ?? false

        console.log(badgeStatus)
      }
      return res.status(200).json(badgeStatus)
    }
    catch(err){
      console.error('Internal server error')
      return res.status(500).json('Internal server error')
    }
  } catch (error) {
    console.error("Error in sendBadgeData:", error);
    return res.status(500).json({ error: "Internal Server Error" });
  }
}

export const sendDailyGerdReport = async (req, res) => {
  try {
    const { uid, date, gerdCount } = req.body;

    if (!uid) return res.status(400).json('UID is required');
    if (typeof gerdCount !== 'number' || gerdCount < 0)
      return res.status(400).json('gerdCount must be a non-negative number');

    let prevDate = new Date(date);
    prevDate.setDate(prevDate.getDate() - 1);

    const year = prevDate.getFullYear();
    const month = String(prevDate.getMonth() + 1).padStart(2, '0');
    const day = String(prevDate.getDate()).padStart(2, '0');

    const prevDateStr = `${year}-${month}-${day}`;
    const dayNumberStr = String(prevDate.getDate()); // ini key-nya, misal '7'
    const monthAndYear = `${year}-${month}`;

    try {
      // Ambil data GERD bulanan sebelumnya
      const prevGerdDoc = await db
        .collection('users')
        .doc(uid)
        .collection('streak_gerd_data')
        .doc(monthAndYear)
        .get();

      const prevGerdData = prevGerdDoc.exists ? prevGerdDoc.data() : {};
      let monthlyGerdCount = prevGerdData.monthlyGerdCount ?? 0;
      let monthlyGerdCountDetail = prevGerdData.monthlyGerdCountDetail ?? {};

      // Tambah total dan detail
      monthlyGerdCount += gerdCount;
      monthlyGerdCountDetail[dayNumberStr] = gerdCount;

      // Update user streak
      const userDoc = await db.collection('users').doc(uid).get();
      const userData = userDoc.data();
      let currentNoGerdStreak = userData?.currentNoGerdStreak ?? 0;

      if (gerdCount === 0) {
        currentNoGerdStreak++;
      } else {
        currentNoGerdStreak = 0;
      }

      // Simpan data ke Firestore
      await db.collection('users').doc(uid).collection('history').doc(prevDateStr).set({
        dailyGerdCount: gerdCount
      }, { merge: true });

      await db.collection('users').doc(uid).collection('streak_gerd_data').doc(monthAndYear).set({
        monthlyGerdCount,
        monthlyGerdCountDetail
      }, { merge: true });

      await db.collection('users').doc(uid).set({
        currentNoGerdStreak
      }, { merge: true });

      res.status(200).json('Success sending daily gerd report to database');
    } catch (err) {
      console.error(err);
      res.status(400).json('Failed sending daily gerd report to database');
    }
  } catch (error) {
    console.error("Error in sendDailyGerdReport:", error);
    return res.status(500).json({ error: "Internal Server Error" });
  }
};

export const sendGerdTriggererInformation = async (req, res) => {
  try {
    const { uid, date} = req.body;
    if (!uid) return res.status(400).json('UID is required');
    
    let prevDate = new Date(date);
    prevDate.setDate(prevDate.getDate() - 1);

    const year = prevDate.getFullYear();
    const month = String(prevDate.getMonth() + 1).padStart(2, '0');
    const day = String(prevDate.getDate()).padStart(2, '0');

    const prevDateStr = `${year}-${month}-${day}`

    try {
    
      const historyDoc = await db.collection('users').doc(uid).collection('history').doc(prevDateStr).get()

      if (!historyDoc.exists) {
        return res.status(404).json({message : "Cannot found data on previous date!"})
      }
      const historyData = historyDoc.data()

      res.status(200).json(historyData);
    } catch (err) {
      console.error(err);
      res.status(400).json('Failed sending daily gerd report to database');
    }
  } catch (error) {
    console.error("Error in sendGerdTriggererInformation:", error);
    return res.status(500).json({ error: "Internal Server Error" });
  }
};

export const getMealRecommendation = async (req,res) => {
  try {
    // urutan data yang dikirim harus urut kek dibawah ini
    // "Kardiovaskular, Diabetes, Pernapasan, Anemia, Kolesterol, Obesitas"
    const {uid} = req.body;
    // console.log(uid)
    if(!uid) return res.status(401).json('UID is required')
    
    try{
      const checkedFieldsDoc = await db.collection("users").doc(uid).get()
      if (checkedFieldsDoc.empty) {
        return res.status(404).json({ error: "No notifications found" });
      }
    
      const checkedFields = checkedFieldsDoc.data().diseases
    
      
      // bentuknya tetep dibuat kek gini aja, "Kardiovaskular, Diabetes, Pernapasan, Anemia, Kolesterol, Obesitas"
      const data = foodRecommendation.kombinasi_gerd_penyakit.find(item => item.kondisi == checkedFields)
      if(!data){
        return res.status(404).json({error : "Cannot find specific condition"})
      }
      const list_of_food = data.daftar_makanan
      const randomize_list_of_food = list_of_food.sort(() => Math.random() - 0.5)
      res.status(200).json(randomize_list_of_food.slice(0,4))
    }
    catch(err){
      res.status(400).json('No specific condition is found!')
    }
  } catch (error) {
    console.error("Error in getMealRecommendation:", error);
    return res.status(500).json({ error: "Internal Server Error" });
  }
}
export const changeDrinkStatusToTrue = async (req,res) => {
  try {
    const {uid,date} = req.body

    if(!uid || !date){
      return res.status(400).json('Data is missing')
    }
    try{ 
      //format untuk date -> 2025-05-01
      await db.collection("users").doc(uid).collection("history").doc(date).set({
        isDrink : true,
      },{merge : true});
      console.log('Success updating isDrink status')
      res.status(200).json("Success updating isDrink status");
    }
    catch(err){
      console.log(err)
      res.status(500).json('Error while scanning photo',err)
    }
  } catch (error) {
    console.error("Error in changeDrinkStatusToTrue:", error);
    return res.status(500).json({ error: "Internal Server Error" });
  }
}

export const sendScannedPhotoResult = async (req,res) => {
  try{ 
    //type adalah tipe makannya sarapan, makan siang, atau makan malam
    const {uid} = req.body
    const buffer = req.file.buffer

    if(!uid){
      return res.status(400).json('UID is required')
    }
    if(!buffer){
      return res.status(400).json('No photo scanned')
    }

    const result = await scanPhotoWithGemini(buffer);
    res.status(200).json(result);
  }
  catch(err){
    console.log(err)
    res.status(500).json('Error while scanning photo',err)
  }
}

// upload photo dan data komponen makanan apa saja yang dipilih user
// gunakan multipart/form-data
// foodcomponent boleh bertipe object atau masih string 
export const uploadPhotoAndFoodComponentToDatabase = async (req,res) => {
  try {
    //mealTime -> (breakfast/lunch/dinner)
    const {uid, mealTime} = req.body
    let {foodComponent} = req.body
    console.log('req.file:', req.file);
    const buffer = req.file.buffer
    try{ 
      if(!uid){
        return res.status(400).json('UID is required')
      }
      if(!buffer){
        return res.status(400).json('No photo uploaded')
      }
      if (!foodComponent ) {
        return res.status(400).json('Food component must be a valid object or array');
      }

      if(typeof foodComponent != 'object'){
        foodComponent = JSON.parse(foodComponent);
      }

      foodComponent = {
        [`${mealTime}`] : foodComponent.makanan
      }

      const dateString = formatDate()
      const timeString = formatTime()
      
      const fileName = `${dateString}-${mealTime}`;
      const fileLink = await uploadFileToDrive(buffer,fileName)
      console.log(fileLink)
      await db.collection('users')
      .doc(uid)
      .collection('history')
      .doc(dateString)
      .set({
        [`${mealTime}Link`]: fileLink,
        [`${mealTime}Time`]: timeString,
        foodComponent,
      }, { merge: true });

      res.status(200).json({
        message: 'File dan informasi komponen berhasil diupload',
        fileLink,
      });
    }
    catch(err){
      console.log(err)
      res.status(500).json('Error while uploading file')
    }
  } catch (error) {
    console.error("Error in uploadPhotoAndFoodComponentToDatabase:", error);
    return res.status(500).json({ error: "Internal Server Error" });
  }
}

//calendar
export const getDataOnSpecificDate = async (req,res) => {
  try {
    // format date : "2025-05-01"
    const {uid, year_month_date} = req.body
    
    const historyDoc = await db.collection('users').doc(uid).collection('history').doc(year_month_date).get()
    // harusnya gausah dikasih conditioning, karena historyData pasti akan auto diisi oleh controller oleh daily report
    if (!historyDoc.exists) {
      return res.status(200).json({message : "Data belum ada"})
    }

    const historyData = historyDoc.data()
    // isinya data adalah :
    // waktu breakfast, lunch, dinner dan link masing masing fotonya beserta komponen makanan yang udah dia pilih
    // streak di tanggal itu
    // (dapetin gerd harian) apakah dia kena gerd? kalok kena berapa banyak berdasarkan inputan manual dia 

    res.status(200).json(historyData)
  } catch (error) {
    console.error("Error in getDataOnSpecificDate:", error);
    return res.status(500).json({ error: "Internal Server Error" });
  }
}

//calendar
export const getDataOnSpecificMonth = async (req,res) => {
  try {
    // year_month formatnya "2025-05"
    const {uid, year_month} = req.body
    
    // dapetin api akumulatif (currentStreak) -> dapetinnya dari collection('users).doc(uid)
    const userDoc = await db.collection('users').doc(uid).get()
    const userData = userDoc.data();
    const currentStreak = userData.currentStreak
    
    // dapetin gerd bulanan dan api bulanan -> dapetinnya dari collection('users).doc(uid).collection('streak_gerd_data').doc().
    const fireGerdStreakDoc = await db.collection('users').doc(uid).collection('streak_gerd_data').doc(year_month).get();
    const fireGerdStreakData = fireGerdStreakDoc.data()
    if (!fireGerdStreakDoc.exists || !fireGerdStreakData) return res.status(400).json("No data is found")

    
    const data = {
      currentStreak,
      monthlyReport : fireGerdStreakData.monthlyReport,
      monthlyGerdCount : fireGerdStreakData.monthlyGerdCount,
      monthlyGerdCountDetail : fireGerdStreakData.monthlyGerdCountDetail
    }
    console.log(data)

    res.status(200).json(data)
  } catch (error) {
    console.error("Error in getDataOnSpecificMonth:", error);
    return res.status(500).json({ error: "Internal Server Error" });
  }
}


export const testingFoodComponent = async (req,res) => {
  try {
    const {uid, foodComponent} = req.body
    await db.collection("users").doc(uid).collection("history").doc("2025-05-14").set({
      foodComponent
    },{merge: true})
    res.status(200).json("Berhasil testing")
  } catch (error) {
    console.error("Error in testingFoodComponent:", error);
    return res.status(500).json({ error: "Internal Server Error" });
  }
}

export const testingFoodPhotoAndTime = async (req,res) => {
  try {
    const {uid, breakfastLink, breakfastTime, lunchLink, lunchTime, dinnerLink, dinnerTime} = req.body

    await db.collection("users").doc(uid).collection("history").doc("2025-05-14").set({
      breakfastLink,
      breakfastTime,
      lunchLink,
      lunchTime,
      dinnerLink,
      dinnerTime
    },{merge: true})
    res.status(200).json("Berhasil testing")
  } catch (error) {
    console.error("Error in testingFoodPhotoAndTime:", error);
    return res.status(500).json({ error: "Internal Server Error" });
  }
}