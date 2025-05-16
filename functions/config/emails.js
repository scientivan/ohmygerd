import nodemailer from "nodemailer"
import {google} from 'googleapis'
import env from 'dotenv'

if (process.env.NODE_ENV !== 'production') {
  env.config({ path: '../.env' });
}

const oAuth2Client = new google.auth.OAuth2(
  process.env.NODEMAILER_CLIENT_ID,
  process.env.NODEMAILER_CLIENT_SECRET,
  process.env.REDIRECT_URI
); 

oAuth2Client.setCredentials({refresh_token : process.env.REFRESH_TOKEN})

export const getTransporter = async () => {
  const accessToken = await oAuth2Client.getAccessToken()
  
  const transporter = nodemailer.createTransport({
    service : 'gmail',
    auth : {
      type: 'OAuth2',
      user: process.env.EMAIL_ADMIN,
      clientId: process.env.NODEMAILER_CLIENT_ID,
      clientSecret: process.env.NODEMAILER_CLIENT_SECRET,
      refreshToken: process.env.REFRESH_TOKEN,
      accessToken: accessToken,
    }
  })
  return transporter
}



