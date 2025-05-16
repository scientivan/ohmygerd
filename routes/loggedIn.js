import express from 'express'
import {testingFoodPhotoAndTime, uploadPhotoAndFoodComponentToDatabase, getMealRecommendation,getDataOnSpecificDate, getDataOnSpecificMonth, sendScannedPhotoResult, sendDailyGerdReport, changeDrinkStatusToTrue, getListOfNotification,sendBadgeData, sendGerdTriggererInformation, testingFoodComponent} from '../controllers/loggedInController.js'
import {findFriendsByGmail, getListOfConnection, handleAddedConnection, handleDeleteConnection } from '../controllers/emailController.js'
import { chatbotResponse, getChatHistory, getRestaurantRecommendation } from '../controllers/chatBotController.js'
import multer from 'multer'

const storage = multer.memoryStorage(); 
const upload = multer({ storage: storage });
const router = express.Router()

// router.use(authenticateFirebase)

const routes = [
    //jangan ada routes yang fungsinya sebagai boleh masuk atau nggaknya user ke suatu halaman di BACKEND (karena itu akan di handle di FE,
    
    // auto load while accesing homepage
    { method: 'post', path: '/getMealRecommendation', action: getMealRecommendation}, //V // ngeshow semua task yang ada dan blom completed
    { method: 'post', path: '/sendDailyGerdReport', action: sendDailyGerdReport}, //V // ngeshow semua task yang ada dan blom completed
    { method: 'post', path: '/sendGerdTriggererInformation', action: sendGerdTriggererInformation}, //V // ngeshow semua task yang ada dan blom completed
    
    { method: 'post', path: '/getListOfNotification', action: getListOfNotification}, //V // ngeshow semua task yang ada dan blom completed
    { method: 'post', path: '/sendBadgeData', action: sendBadgeData}, //V // ngeshow semua task yang ada dan blom completed
    
    { method: 'post', path: '/testingFoodComponent', action: testingFoodComponent}, //V // ngeshow semua task yang ada dan blom completed
    { method: 'post', path: '/testingFoodPhotoAndTime', action: testingFoodPhotoAndTime}, //V // ngeshow semua task yang ada dan blom completed
    
    // Meal Scanner and reminder
    { method: 'post', path: '/uploadPhotoAndFoodComponent', middlewares : [upload.single('photo')], action: uploadPhotoAndFoodComponentToDatabase}, //V // ngeshow semua task yang ada dan blom completed
    { method: 'post', path: '/sendScannedPhotoResult', middlewares : [upload.single('photo')], action: sendScannedPhotoResult}, //V // ngeshow semua task yang ada dan blom completed
    { method: 'post', path: '/changeDrinkStatusToTrue', action: changeDrinkStatusToTrue}, //V // ngeshow semua task yang ada dan blom completed
    
    // calendar
    { method: 'post', path: '/getDataOnSpecificDate', action: getDataOnSpecificDate}, //V // ngeshow semua task yang ada dan blom completed
    { method: 'post', path: '/getDataOnSpecificMonth', action: getDataOnSpecificMonth}, //V // ngeshow semua task yang ada dan blom completed
    
    // connection
    { method: 'post', path: '/api/contacts', action:findFriendsByGmail }, //V // ngeshow semua task yang ada dan blom completed
    { method: 'post', path: '/getListOfConnection', action: getListOfConnection}, //V // ngeshow semua task yang ada dan blom completed
    { method: 'post', path: '/handleAddedConnection', action: handleAddedConnection}, //V // ngeshow semua task yang ada dan blom completed
    { method: 'post', path: '/handleDeleteConnection', action: handleDeleteConnection}, //V // ngeshow semua task yang ada dan blom completed
    
    // chatbot
    { method: 'post', path: '/getRestaurantRecommendation', action: getRestaurantRecommendation}, //V // ngeshow semua task yang ada dan blom completed
    { method: 'post', path: '/chatbotResponse', action: chatbotResponse}, //V // ngeshow semua task yang ada dan blom completed
    { method: 'post', path: '/getChatHistory', action: getChatHistory}, //V // ngeshow semua task yang ada dan blom completed
  
  ]
  
  routes.forEach(route => {
    if(route.middlewares){
      router[route.method](route.path, ...route.middlewares, route.action)
    }
    else{
      router[route.method](route.path, route.action)
    }
  })

export default router