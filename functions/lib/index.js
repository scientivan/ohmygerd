// Firebase Cloud Functions with optimized initialization
import * as functions from "firebase-functions/v1";
import admin from "firebase-admin";
import db from "./firestore.js";
import { formatDate, parseMinutesFromTimeString, formatMonthYear, formatDateForYesterday, formatTime } from "../utils/tools.js";
import { getTransporter } from "../config/emails.js";
import 'dotenv/config';

// --------------------------------
// Core utility functions
// --------------------------------

/**
 * Safely executes a function and logs errors
 * @param {Function} fn - Function to execute
 * @param {string} errorContext - Context for error logging
 * @returns {Promise<any>} - Result of the function or null on error
 */
const safeExecute = async (fn, errorContext) => {
    try {
        return await fn();
    } catch (error) {
        console.error(`Error in ${errorContext}:`, error);
        return null;
    }
};

/**
 * Sends a push notification to a user
 * @param {string} fcmToken - FCM token to send notification to
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @returns {Promise<void>}
 */
const sendPushNotification = async (fcmToken, title, body) => {
    if (!fcmToken) return null;
    
    return safeExecute(async () => {
        await admin.messaging().send({
            token: fcmToken,
            notification: { title, body },
        });
    }, "sending push notification");
};

/**
 * Saves a notification to the user's notification collection
 * @param {string} uid - User ID
 * @param {string} title - Notification title
 * @param {string} desc - Notification description
 * @returns {Promise<void>}
 */
const saveNotificationToDatabase = async (uid, title, desc) => {
    return safeExecute(async () => {
        // Add a document reference with a unique ID before calling .set()
        await db.collection("users").doc(uid).collection('notification').doc().set({
            title,
            desc,
            time: formatTime(),
            date: formatDate(),
        });
    }, "saving notification to database");
};

/**
 * Gets user meal preferences
 * @param {string} uid - User ID
 * @returns {Promise<Object|null>} - Meal preferences or null
 */
const getUserMealPreferences = async (uid) => {
    return safeExecute(async () => {
        const userMealDoc = await db.collection("users").doc(uid).collection('preferences').doc('meal_snack_time').get();
        return userMealDoc.exists ? userMealDoc.data() : null;
    }, "getting user meal preferences");
};

// --------------------------------
// Cloud Functions
// --------------------------------

/**
 * Sends snack reminders to users based on their preferences
 */
export const sendSnackNotification = functions.pubsub
    .schedule("every 30 minutes")
    .timeZone("Asia/Jakarta")
    .onRun(async () => {
        try {
            const now = new Date();
            const currentHour = now.getHours();
            
            // Only send notifications between 6:00 and 21:00
            if (currentHour < 6 || currentHour > 21) return null;
            
            try {
                const usersSnapshot = await db.collection("users").get();
                
                for (const userDoc of usersSnapshot.docs) {
                    try {
                        const uid = userDoc.id;
                        if (!uid) continue;
                        
                        const fcmToken = userDoc.data().fcmToken;
                        if (!fcmToken) continue;
                        
                        try {
                            const userMealDoc = await db.collection("users").doc(uid).collection('preferences').doc('meal_snack_time').get();
                            const userMealData = userMealDoc.data();
                            
                            if (!userMealData) continue;
                            if (currentHour > userMealData.maxSnackTime) continue;
                            
                            const reminderInterval = userMealData.reminderInterval;
                            if (reminderInterval <= 0) continue;
                            
                            const lastSent = userMealData.lastReminderSentAt ? 
                                new Date(userMealData.lastReminderSentAt) : 
                                new Date(0);
                                
                            const hoursSinceLast = (now.getTime() - lastSent.getTime()) / (1000 * 60 * 60);
                            
                            if (hoursSinceLast >= reminderInterval) {
                                try {
                                    await admin.messaging().send({
                                        token: fcmToken,
                                        notification: {
                                            title: "🔔 Snack-time alert!",
                                            body: `Lewat ${reminderInterval} jam tanpa snack? Ayo ambil sekarang!`,
                                            
                                        },
                                    });
                                    
                                    try {
                                        await db.collection("users").doc(uid).collection('notification').doc().set({
                                            title: "🔔 Snack-time alert!",
                                            body: `Lewat ${reminderInterval} jam tanpa snack? Ayo ambil sekarang!`,
                                            time: formatTime(),
                                            date: formatDate(),
                                        });
                                    } catch (notificationError) {
                                        console.error("Gagal menyimpan data notifikasi:", notificationError);
                                    }
                                    
                                    try {
                                        await db.collection("users").doc(uid)
                                            .collection("preferences")
                                            .doc("meal_snack_time")
                                            .update({
                                                lastReminderSentAt: now.toISOString(),
                                            });
                                    } catch (updateError) {
                                        console.error("Gagal memperbarui lastReminderSentAt:", updateError);
                                    }
                                } catch (messagingError) {
                                    console.error("Gagal mengirim notifikasi:", messagingError);
                                }
                            }
                        } catch (userMealError) {
                            console.error("Gagal mengambil data meal user:", userMealError);
                        }
                    } catch (userDocError) {
                        console.error("Gagal memproses dokumen user:", userDocError);
                    }
                }
            } catch (usersError) {
                console.error("Terjadi kesalahan saat mengambil data pengguna:", usersError);
            }
        } catch (mainError) {
            console.error("Terjadi kesalahan utama pada fungsi sendSnackNotification:", mainError);
        }
        return null;
});

// export const sendSnackNotificationTest = functions.pubsub
//     .schedule("every 3 minutes") // GANTI JADWALNYA JADI LEBIH CEPAT
//     .timeZone("Asia/Jakarta")
//     .onRun(async () => {
//         try {
//             const now = new Date();
//             const currentHour = now.getHours();
            
//             // Tetap batasi jam pengiriman agar tidak mengganggu malam hari
//             if (currentHour < 6 || currentHour > 21) return null;
            
//             const usersSnapshot = await db.collection("users").get();
            
//             for (const userDoc of usersSnapshot.docs) {
//                 const uid = userDoc.id;
//                 if (!uid) continue;

//                 const fcmToken = userDoc.data().fcmToken;
//                 if (!fcmToken) continue;

//                 const userMealDoc = await db
//                     .collection("users")
//                     .doc(uid)
//                     .collection('preferences')
//                     .doc('meal_snack_time')
//                     .get();

//                 const userMealData = userMealDoc.data();
//                 if (!userMealData) continue;
//                 if (currentHour > userMealData.maxSnackTime) continue;

//                 const reminderInterval = userMealData.reminderInterval || 0.05; // default 3 menit (0.05 jam)
//                 const lastSent = userMealData.lastReminderSentAt
//                     ? new Date(userMealData.lastReminderSentAt)
//                     : new Date(0);

//                 const hoursSinceLast = (now.getTime() - lastSent.getTime()) / (1000 * 60 * 60);

//                 if (hoursSinceLast >= reminderInterval) {
//                     // Kirim notifikasi testing
//                     await admin.messaging().send({
//                         token: fcmToken,
//                         notification: {
//                             title: "🔔 Snack-time alert!",
//                             body: `Lewat ${reminderInterval * 60} jam tanpa snack? Ayo ambil sekarang!`,
//                         },
//                     });

//                     // Simpan notifikasi
//                     await db.collection("users").doc(uid).collection('notification').add({
//                         title: "🔔 Snack-time alert!",
//                         desc: `Lewat ${reminderInterval * 60} jam tanpa snack? Ayo ambil sekarang!`,
//                         time: formatTime(),
//                         date: formatDate(),
//                     });

//                     // Update waktu terakhir notifikasi
//                     await db.collection("users").doc(uid)
//                         .collection("preferences")
//                         .doc("meal_snack_time")
//                         .update({
//                             lastReminderSentAt: now.toISOString(),
//                         });
//                 }
//             }
//         } catch (error) {
//             console.error("Error on sendSnackNotificationTest:", error);
//         }

//         return null;
//     });


/**
 * Sends meal reminders to users based on their preferences
 */
export const sendEatNotification = functions.pubsub
    .schedule("every 30 minutes")
    .timeZone("Asia/Jakarta")
    .onRun(async () => {
        try {
            const now = new Date();
            const currentHour = now.getHours();
            let status, statusIndo;
            
            // Determine current meal time
            if (currentHour >= 5 && currentHour <= 9) {
                status = "breakfast";
                statusIndo = "makan pagi";
            } else if (currentHour >= 11 && currentHour <= 15) {
                status = "lunch";
                statusIndo = "makan siang";
            } else if (currentHour >= 17 && currentHour <= 21) {
                status = "dinner";
                statusIndo = "makan malam";
            } else {
                return null;
            }
            
            try {
                const currentMinutes = (currentHour * 60) + now.getMinutes();
                const usersSnapshot = await db.collection("users").get();
                
                for (const userDoc of usersSnapshot.docs) {
                    try {
                        const uid = userDoc.id;
                        if (!uid) continue;
                        
                        const fcmToken = userDoc.data().fcmToken;
                        if (!fcmToken) continue;
                        
                        try {
                            const userMealDoc = await db.collection("users").doc(uid).collection('preferences').doc('meal_snack_time').get();
                            const userMealData = userMealDoc.data();
                            
                            if (!userMealData) continue;
                            
                            let time;
                            let updateField = "";
                            
                            // Get the appropriate time based on meal status
                            switch(status) {
                                case "breakfast":
                                    if (!userMealData.isBreakFast) {
                                        time = userMealData.breakfastTime;
                                        updateField = "isBreakFast";
                                    }
                                    break;
                                case "lunch":
                                    if (!userMealData.isLunch) {
                                        time = userMealData.lunchTime;
                                        updateField = "isLunch";
                                    }
                                    break;
                                case "dinner":
                                    if (!userMealData.isDinner) {
                                        time = userMealData.dinnerTime;
                                        updateField = "isDinner";
                                    }
                                    break;
                            }
                            
                            if (!time || typeof time !== "string") continue;
                            
                            try {
                                console.log(time)
                                const minutes = parseMinutesFromTimeString(time);
                                
                                if (currentMinutes >= minutes) {
                                    try {
                                        await admin.messaging().send({
                                            token: fcmToken,
                                            notification: {
                                                title: `🍔 Waktunya ${statusIndo} sekarang!`,
                                                body: `Cepat makan sebelum waktunya habis! Apimu menunggu di OhMyGerd!`,
                                            },

                                        });
                                        
                                        try {
                                            await db.collection("users").doc(uid).collection('notification').doc().set({
                                                title: `🍔 Waktunya ${statusIndo} sekarang!`,
                                                body: `Cepat makan sebelum waktunya habis! Apimu menunggu di OhMyGerd!`,
                                                time: formatTime(),
                                                date: formatDate(),
                                            });
                                        } catch (notificationError) {
                                            console.error("Gagal menyimpan data notifikasi:", notificationError);
                                        }
                                        
                                        if (updateField) {
                                            try {
                                                const updateData = {};
                                                updateData[updateField] = true;
                                                
                                                await db.collection("users").doc(uid)
                                                    .collection("preferences")
                                                    .doc("meal_snack_time")
                                                    .update(updateData);
                                            } catch (updateError) {
                                                console.error("Gagal update status makan:", updateError);
                                            }
                                        }
                                    } catch (messagingError) {
                                        console.error("Gagal mengirim notifikasi:", messagingError);
                                    }
                                }
                            } catch (timeParseError) {
                                console.error("Gagal memparse waktu:", timeParseError);
                            }
                        } catch (userMealError) {
                            console.error("Gagal mengambil data meal user:", userMealError);
                        }
                    } catch (userDocError) {
                        console.error("Gagal memproses dokumen user:", userDocError);
                    }
                }
            } catch (usersError) {
                console.error("Terjadi kesalahan saat mengambil data pengguna:", usersError);
            }
        } catch (mainError) {
            console.error("Terjadi kesalahan utama pada fungsi sendEatNotification:", mainError);
        }
        return null;
    });

    // export const testSendEatNotification = functions.pubsub
    // .schedule("every 5 minutes") // testing interval
    // .timeZone("Asia/Jakarta")
    // .onRun(async () => {
    //     try {
    //         const now = new Date();
    //         const currentHour = now.getHours();
    //         const currentMinutes = (currentHour * 60) + now.getMinutes();

    //         const status = "test_meal";
    //         const statusIndo = "makan siang";

    //         const usersSnapshot = await db.collection("users").get();

    //         for (const userDoc of usersSnapshot.docs) {
    //             const uid = userDoc.id;
    //             if (!uid) continue;

    //             const fcmToken = userDoc.data().fcmToken;
    //             if (!fcmToken) continue;

    //             try {
    //                 const userMealDoc = await db.collection("users").doc(uid).collection('preferences').doc('meal_snack_time').get();
    //                 const userMealData = userMealDoc.data();

    //                 if (!userMealData) continue;

    //                 // Untuk testing, kita pakai waktu acak atau langsung loloskan
    //                 const time = userMealData.breakfastTime || "06:00"; // fallback waktu
    //                 const updateField = "isBreakFast"; // bebas, untuk testing

    //                 const minutes = parseMinutesFromTimeString(time);
                    
    //                 // if (currentMinutes >= minutes) {
    //                     await admin.messaging().send({
    //                         token: fcmToken,
    //                         notification: {
    //                             title: `🍔 Waktunya ${statusIndo} sekarang!`,
    //                             body: `Cepat makan sebelum waktunya habis! Apimu menunggu di OhMyGerd!`,
    //                         },
    //                     });

    //                     await db.collection("users").doc(uid).collection('notification').doc().set({
    //                         title: `🍔 Waktunya ${statusIndo} sekarang!`,
    //                         desc: `Cepat makan sebelum waktunya habis! Apimu menunggu di OhMyGerd!`,
    //                         time: formatTime(),
    //                         date: formatDate(),
    //                     });

    //                     // Update status supaya tidak spam saat testing
    //                     await db.collection("users").doc(uid)
    //                         .collection("preferences")
    //                         .doc("meal_snack_time")
    //                         .update({
    //                             [updateField]: true,
    //                         });
    //                 // }
    //             } catch (error) {
    //                 console.error("❌ Error saat testing notifikasi:", error);
    //             }
    //         }
    //     } catch (mainError) {
    //         console.error("❌ Kesalahan utama pada testSendEatNotification:", mainError);
    //     }
    //     return null;
    // });


/**
 * Checks user streaks daily and updates statistics
 */
export const checkStreak = functions.pubsub
    .schedule("0 0 * * *") // Run every day at midnight
    .timeZone("Asia/Jakarta")
    .onRun(async () => {
        try {
            try {
                const usersSnapshot = await db.collection('users').get();
                
                for (const userDoc of usersSnapshot.docs) {
                    try {
                        const uid = userDoc.id;
                        if (!uid) continue;
                        
                        const userData = userDoc.data();
                        if (!userData) continue;
                        
                        try {
                            // Reset daily count
                            const todayDate = formatDate();
                            await db.collection('users').doc(uid).collection('history').doc(todayDate).set({
                                dailyGerdCount: 0
                            }, {merge : true});
                        } catch (historyError) {
                            console.error(`Gagal update history untuk user ${uid}:`, historyError);
                        }
                        
                        try {
                            // Check yesterday's streak eligibility
                            const yesterdayId = formatDateForYesterday();
                            const userHistoryDoc = await db.collection('users').doc(uid).collection('history').doc(yesterdayId).get();
                            const userHistoryData = userHistoryDoc.data();
                            
                            const incomplete =
                                !userHistoryData ||
                                userHistoryData.breakfastLink == null ||
                                userHistoryData.lunchLink == null ||
                                userHistoryData.dinnerLink == null ||
                                userHistoryData.isDrink === false;
                            
                            let currentStreak = userData.currentStreak || 0;
                            const now = new Date();
                            
                            if (incomplete) {
                                // Reset streak
                                currentStreak = 0;
                                
                                try {
                                    await userDoc.ref.update({
                                        currentStreak,
                                        lastStreakDate: now.toISOString(),
                                    });
                                } catch (updateError) {
                                    console.error(`Gagal update streak untuk user ${uid}:`, updateError);
                                }
                                
                                try {
                                    await userHistoryDoc.ref.set({ streak: currentStreak }, { merge: true });
                                } catch (historyUpdateError) {
                                    console.error(`Gagal update history streak untuk user ${uid}:`, historyUpdateError);
                                }
                            } else {
                                // Increment streak
                                currentStreak++;
                                
                                try {
                                    await userDoc.ref.update({
                                        currentStreak,
                                        lastStreakDate: now.toISOString(),
                                    });
                                } catch (updateError) {
                                    console.error(`Gagal update streak untuk user ${uid}:`, updateError);
                                }
                                
                                try {
                                    await userHistoryDoc.ref.set({ streak: currentStreak }, { merge: true });
                                } catch (historyUpdateError) {
                                    console.error(`Gagal update history streak untuk user ${uid}:`, historyUpdateError);
                                }
                                
                                try {
                                    const month_year = formatMonthYear();
                                    const streakDataDoc = await db
                                        .collection("users")
                                        .doc(uid)
                                        .collection("streak_gerd_data")
                                        .doc(month_year).get();
                                    
                                    const streakDataData = streakDataDoc.data();
                                    let monthlyReport = streakDataDoc.exists ? streakDataData.monthlyReport : 0;
                                    monthlyReport++;
                                    
                                    await db
                                        .collection("users")
                                        .doc(uid)
                                        .collection("streak_gerd_data")
                                        .doc(month_year).set(
                                            { monthlyReport },
                                            { merge: true }
                                        );
                                } catch (streakDataError) {
                                    console.error(`Gagal update streak data bulanan untuk user ${uid}:`, streakDataError);
                                }
                            }
                        } catch (yesterdayCheckError) {
                            console.error(`Gagal memeriksa data kemarin untuk user ${uid}:`, yesterdayCheckError);
                        }
                    } catch (userProcessError) {
                        console.error("Gagal memproses user:", userProcessError);
                    }
                }
            } catch (usersError) {
                console.error("Gagal mendapatkan daftar users:", usersError);
            }
        } catch (mainError) {
            console.error("Terjadi kesalahan utama pada fungsi checkStreak:", mainError);
        }
        return null;
    });

/**
 * Checks and awards badges based on streak achievements
 */
export const checkStreakForBadge = functions.firestore
    .document('users/{userId}')
    .onUpdate(async (change, context) => {
        try {
            const userId = context.params.userId;
            const oldValue = change.before.data();
            const newValue = change.after.data();
            
            if (oldValue.currentStreak === newValue.currentStreak) return null;
            
            const currentStreak = newValue.currentStreak;
            
            // Define badge thresholds
            const badges = {
                10: '10Badge',
                30: '30Badge',
                100: '100Badge',
                300: '300Badge',
                500: '500Badge'
            };
            
            const badge = badges[currentStreak] || null;
            
            if (badge && !newValue[`is${badge}`]) {
                try {
                    await db.collection('users').doc(userId).set({
                        [`is${badge}`]: true
                    }, {merge: true});
                } catch (badgeUpdateError) {
                    console.error(`Gagal update badge untuk user ${userId}:`, badgeUpdateError);
                }
            }
        } catch (mainError) {
            console.error("Terjadi kesalahan pada fungsi checkStreakForBadge:", mainError);
        }
        return null;
    });

/**
 * Schedule functions for checking meals
 */
export const checkMorningMeal = functions.pubsub
    .schedule("30 8 * * *") // 8:30 AM
    .timeZone("Asia/Jakarta")
    .onRun(async () => {
        try {
            return await checkMealAndSendEmailNotificationToConnection("Breakfast");
        } catch (error) {
            console.error("Error in checkMorningMeal:", error);
            return null;
        }
    });

export const checkLunchMeal = functions.pubsub
    .schedule("30 14 * * *") // 2:30 PM
    .timeZone("Asia/Jakarta")
    .onRun(async () => {
        try {
            return await checkMealAndSendEmailNotificationToConnection("Lunch");
        } catch (error) {
            console.error("Error in checkLunchMeal:", error);
            return null;
        }
    });

export const checkDinnerMeal = functions.pubsub
    .schedule("30 20 * * *")
    .timeZone("Asia/Jakarta")
    .onRun(async () => {
        try {
            return await checkMealAndSendEmailNotificationToConnection("Dinner");
        } catch (error) {
            console.error("Error in checkDinnerMeal:", error);
            return null;
        }
    });

/**
 * Common function to check meals and send email notifications to connections
 */
const checkMealAndSendEmailNotificationToConnection = async (mealStatus) => {
    try {
        // Map meal types to Indonesian names
        const mealTypes = {
            "Breakfast": "sarapan",
            "Lunch": "makan siang",
            "Dinner": "makan malam"
        };
        const statusIndo = mealTypes[mealStatus];
        
        try {
            const usersSnapshot = await db.collection("users").get();
            
            for (const userDoc of usersSnapshot.docs) {
                try {
                    const userData = userDoc.data();
                    const uid = userDoc.id;
                    
                    try {
                        const userMealDoc = await db.collection("users").doc(uid).collection("preferences").doc("meal_snack_time").get();
                        if (!userMealDoc.exists) continue;
                        
                        const userMealData = userMealDoc.data();
                        if (!userMealData) continue;
                        
                        if (userMealData[`is${mealStatus}`] == true) continue;
                        
                        try {
                            const connectionsSnapshot = await db
                                .collection("users")
                                .doc(uid)
                                .collection("connection")
                                .get();
                            
                            try {
                                const transporter = await getTransporter();
                                
                                for (const connDoc of connectionsSnapshot.docs) {
                                    try {
                                        const { to } = connDoc.data();
                                        
                                        const mailOptions = {
                                            from: `OhMyGerd <${process.env.EMAIL_ADMIN}>`,
                                            to,
                                            subject: `${(userData.name || "pengguna").trim()} dengan email ${(userData.email).trim()} belum ${statusIndo} hari ini!`,
                                            html: `<h2>Sudah lewat waktu untuk ${statusIndo}!</h2><p>Segera ingatkan ${userData.name || "pengguna"} untuk segera ${statusIndo} dan melakukkan scan di aplikasi OhMyGerd!</p>`,
                                        };
                                        
                                        try {
                                            await transporter.sendMail(mailOptions);
                                            console.log(`✅ Email terkirim ke ${to} untuk ${userData.name}`);
                                        } catch (sendMailError) {
                                            console.error(`❌ Gagal kirim email ke ${to}`, sendMailError);
                                        }
                                    } catch (connDocError) {
                                        console.error("Gagal memproses dokumen koneksi:", connDocError);
                                    }
                                }
                            } catch (transporterError) {
                                console.error("Gagal mendapatkan transporter:", transporterError);
                            }
                        } catch (connectionsError) {
                            console.error(`Gagal mendapatkan koneksi untuk user ${uid}:`, connectionsError);
                        }
                    } catch (userMealError) {
                        console.error(`Gagal mendapatkan preferensi meal untuk user ${uid}:`, userMealError);
                    }
                } catch (userDocError) {
                    console.error("Gagal memproses dokumen user:", userDocError);
                }
            }
        } catch (usersError) {
            console.error("Gagal mendapatkan daftar users:", usersError);
        }
    } catch (mainError) {
        console.error(`Terjadi kesalahan pada fungsi checkMealAndSendEmailNotificationToConnection untuk ${mealStatus}:`, mainError);
    }
    return null;
};