import express from 'express'
import {register, login, addBiodata, getProfile, updateProfile, addMealAndSnackTime, updateUserMealAndSnackTime, sendFCMTokenToDatabase, getUserMealSnackTime, verifyLatestFCMToken} from '../controllers/authController.js'

const router = express.Router()
// router.use(authenticateFirebase)

const routes = [
    //jangan ada routes yang fungsinya sebagai boleh masuk atau nggaknya user ke suatu halaman di BACKEND (karena itu akan di handle di FE,
    // yang di backend cukup dijaga akses API nya aja)

    // { method: 'post', path: '/checkUserExistence', action: checkUserExistence}, //V // ngeshow semua task yang ada dan blom completed
    { method: 'post', path: '/register', action: register}, //V // ngeshow semua task yang ada dan blom completed
    { method: 'post', path: '/login', action: login}, //V // ngeshow semua task yang ada dan blom completed
    { method: 'post', path: '/updateProfile', action: updateProfile}, //V // ngeshow semua task yang ada dan blom completed
    { method: 'post', path: '/getProfile', action: getProfile}, //V // ngeshow semua task yang ada dan blom completed
    { method: 'post', path: '/addBiodata', action: addBiodata}, //V // ngeshow semua task yang ada dan blom completed
    { method: 'post', path: '/getUserMealSnackTime', action: getUserMealSnackTime}, //V // ngeshow semua task yang ada dan blom completed
    { method: 'post', path: '/addMealSnackTime', action: addMealAndSnackTime}, //V // ngeshow semua task yang ada dan blom completed
    { method: 'post', path: '/updateMealSnackTime', action: updateUserMealAndSnackTime}, //V // ngeshow semua task yang ada dan blom completed
    { method: 'post', path: '/verifyLatestFCMToken', action: verifyLatestFCMToken}, //V // ngeshow semua task yang ada dan blom completed
    { method: 'post', path: '/sendFCMToken', action: sendFCMTokenToDatabase}, //V // ngeshow semua task yang ada dan blom completed
  ] 
  
  routes.forEach(route => {
    router[route.method](route.path, route.action)
  })

export default router