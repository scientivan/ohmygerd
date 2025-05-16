import dotenv from 'dotenv'
if (process.env.NODE_ENV !== 'production') {
    dotenv.config();
}
import './config/firestore.js'
import express from 'express'
import methodOverride from 'method-override'
import cors from 'cors'
// import authRoutes from './routes/auth.js'
import loggedInRoutes from './routes/loggedIn.js'
import authRoutes from './routes/auth.js'

const app = express()

app.use(cors());

app.use(express.json()) 
app.use(express.urlencoded())
app.use(methodOverride('_method')) //  buat munculin UPDATE dan DELETE


// app.use((req, res, next) => {
//     if (process.env.NODE_ENV === 'production' && !req.secure) {
//         return res.redirect(`https://${req.headers.host}${req.url}`);
//     }
//     next();
// });

app.use('/auth',authRoutes)  
app.use('/user',loggedInRoutes)  
// app.use('/',authRoutes) gapake auth dari BE karena udah di handle FE dan firebase auth

//handle semua endpoint yang gaada untuk menampilkan 404 not found page
app.get('*', (req, res) => {
    res.status(404).json({ message: 'Not Found' }) // ubah ke res.render('404') jika pakai view engine
})

const PORT = process.env.PORT || 3000
app.listen(PORT,() => {
    console.log(`Server running on port ${process.env.PORT} in ${process.env.NODE_ENV} mode.`)
})

export default app;