import db from '../config/firestore.js'

//function ini bisa nerima profil login yang berasal dari googleauth ataupun login biasa

export const register = async (req, res) => {
  try {
    const { uid, name, email, profilePicture, providerId } = req.body;

    if (!uid || !name || !email) {
      return res.status(400).send({ error: 'Missing required fields' });
    }

    const userDoc = await db.collection('users').doc(uid).get();
    const userData = userDoc.data();
    if (userData && userData.isMealAndSnackTime !== undefined) {
      return res.status(200).json({ isCreated: false });
    }
    

    await db.collection('users').doc(uid).set({
      name,
      email,
      profilePicture,
      providerId,
      isBiodata: false,
      isMealAndSnackTime: false,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    });

    console.log('User profile created successfully');
    res.status(200).send({ message: 'User profile created successfully', isCreated : true  });
  } catch (err) {
    console.error(err);
    res.status(500).send({ error: err.message });
  }
};

export const login = async (req, res) => {
  try {
    const { uid } = req.body;

    if (!uid) {
      return res.status(400).send({ error: 'Missing required fields' });
    }

    const userDoc = await db.collection('users').doc(uid).get();

    if (userDoc.exists) {
      const userData = userDoc.data();

      if (userData.isBiodata == false) {
        console.log('Biodata belum diisi, arahkan ke halaman biodata');
        return res.status(200).send({
          message: 'Biodata has not filled yet. Directing to biodata form filling page.',
          redirectTo: 'biodata'
        });
      }
      if (userData.isMealAndSnackTime == false) {
        console.log('Meal and snack time belum diisi, arahkan ke halaman biodata');
        return res.status(200).send({
          message: 'Meal and snack time has not filled yet. Directing to meal and snack time form filling page',
          redirectTo: 'preference'
        });
      }

      console.log('Successfully Login');
      return res.status(200).send({ message: "Successfully login" });
    } else {
      res.status(404).send('Account not found');
    }
  } catch (err) {
    console.error(err);
    res.status(500).send({ error: err.message });
  }
};

export const addBiodata = async (req, res) => {
  try {
    const { uid, birthDate, gender, weight, diseases } = req.body;

    if (!uid || !birthDate || !gender || !weight) {
      return res.status(400).send({ error: 'Missing required fields' });
    }

    await db.collection('users').doc(uid).set({
      birthDate,
      gender,
      weight,
      diseases,
      isBiodata: true
    }, { merge: true });

    res.status(200).send({ message: 'Biodata addded' });
  } catch (err) {
    res.status(500).send({ error: err.message });
  }
};

export const getProfile = async (req, res) => {
  try {
    const { uid } = req.body;

    const doc = await db.collection('users').doc(uid).get();
    if (!doc.exists) return res.status(404).send({ error: 'Not found' });

    res.status(200).send(doc.data());
  } catch (err) {
    res.status(500).send({ error: err.message });
  }
};

export const updateProfile = async (req, res) => {
  try {
    const { uid, diseases, ...fieldsToUpdate } = req.body;

    if (!uid) {
      return res.status(400).send({ error: 'UID is required' });
    }

    const diseaseOrder = [
      'Kardiovaskular',
      'Diabetes',
      'Pernapasan',
      'Anemia',
      'Kolesterol',
      'Obesitas',
    ];

    let updatedDiseases = "";

    if (diseases) {
      let diseaseArray = diseases.split(",")
        .map(disease => disease.trim())
        .filter(disease => disease !== "");

      if (diseaseArray.length > 0) {
        diseaseArray.sort((a, b) => {
          const indexA = diseaseOrder.indexOf(a);
          const indexB = diseaseOrder.indexOf(b);
          if (indexA === -1) return 1;
          if (indexB === -1) return -1;
          return indexA - indexB;
        });

        updatedDiseases = diseaseArray.join(", ");
      }
    }

    const updatedFields = {
      ...fieldsToUpdate,
      updatedAt: new Date().toISOString(),
    };

    if (diseases !== undefined) {
      updatedFields.diseases = updatedDiseases;
    }

    await db.collection('users').doc(uid).set(updatedFields, { merge: true });

    res.status(200).send({
      message: 'Profile updated',
      updatedFields: updatedFields
    });
  } catch (err) {
    console.error('Error updating profile:', err);
    res.status(500).send({ error: err.message });
  }
};

export const getUserMealSnackTime = async (req, res) => {
  try {
    const { uid } = req.body;

    if (!uid) {
      return res.status(400).send({ error: 'Missing required fields' });
    }

    const userMealSnackTimeDoc = await db.collection('users').doc(uid).collection('preferences').doc('meal_snack_time').get();
    const userMealSnackTimeData = userMealSnackTimeDoc.data();

    res.status(200).send(userMealSnackTimeData);
  } catch (err) {
    console.error(err);
    res.status(500).send({ error: err.message });
  }
};

export const addMealAndSnackTime = async (req, res) => {
  try {
    const { uid, breakfastTime, lunchTime, dinnerTime, snackIntensity, reminderInterval, maxSnackTime, startSnackTime } = req.body;

    if (!uid || !breakfastTime || !lunchTime || !dinnerTime) {
      return res.status(400).send({ error: 'Missing required fields' });
    }

    await db.collection('users').doc(uid).collection('preferences').doc('meal_snack_time').set({
      breakfastTime,
      lunchTime,
      dinnerTime,
      snackIntensity,
      reminderInterval,
      maxSnackTime,
      startSnackTime,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    });

    await db.collection('users').doc(uid).set({
      isMealAndSnackTime: true
    }, { merge: true });

    res.status(200).send({ message: 'Meal and Snack time added successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).send({ error: err.message });
  }
};

export const updateUserMealAndSnackTime = async (req, res) => {
  try {
    const { uid, ...fieldsToUpdate } = req.body;

    if (!uid) {
      return res.status(401).send({ error: 'UID is required' });
    }

    const updatedFields = {
      ...fieldsToUpdate,
      updatedAt: new Date().toISOString()
    };

    await db.collection('users').doc(uid).collection('preferences').doc('meal_snack_time').set(updatedFields, { merge: true });
    res.status(200).send({ message: 'Meal and snack time updated successfully' });
  } catch (err) {
    res.status(500).send({ error: err.message });
  }
};

export const verifyLatestFCMToken = async (req, res) => {
  try {
    const { uid, fcmToken } = req.body;

    if (!uid || !fcmToken) {
      return res.status(400).send({ error: 'Cannot send notification to this UID' });
    }

    const userDoc = await db.collection('users').doc(uid).get();
    const userData = userDoc.data()
    console.log(uid)
    console.log(userData.fcmToken)
    if(userData.fcmToken != null && fcmToken == userData.fcmToken){
      console.log('true')
      return res.status(200).send(true);
    }
    console.log('false')
    return res.status(200).send(false);

  } catch (err) {
    console.error(err);
    res.status(500).send({ error: err.message });
  }
};

export const sendFCMTokenToDatabase = async (req, res) => {
  try {
    const { uid, fcmToken } = req.body;

    if (!uid || !fcmToken) {
      return res.status(400).send({ error: 'Cannot send notification to this UID' });
    }

    await db.collection('users').doc(uid).set({
      fcmToken
    }, { merge: true });

    console.log('FCM Token received successfully');
    res.status(200).send({ message: 'FCM Token received successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).send({ error: err.message });
  }
};
