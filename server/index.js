import express from "express";
import sequelize from "./database.js";

// Import Routers
import productRouter from "./routes/Product.js";
import authRouter from "./routes/auth.js";

const app = express();
const PORT = 3000;

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