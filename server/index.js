import express from "express";
import sequelize from "./database.js";
// import cors from "cors";

// Import Routers
import productRouter from "./routes/Product.js";
import authRouter from "./routes/auth.js";

const app = express();
const PORT = 3000;

// // ✅ Middleware Wajib
// app.use(cors({
//   origin: 'http://localhost:52848', // sementara untuk testing; nanti bisa ubah ke ['http://localhost:52848']
//   methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
//   allowedHeaders: ['Content-Type', 'Authorization'],
// }));

// // Handle preflight OPTIONS
// app.options(/.*/, cors());

app.use(express.json());

// Connect Routes
app.use(productRouter);
app.use(authRouter)

// DB connection Test
sequelize.authenticate()
    .then(() => console.log("MySQL Connected✅"))
    .catch((e) => console.log(e));

app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running at port ${PORT}`);
})