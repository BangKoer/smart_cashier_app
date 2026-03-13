import express from "express";
import sequelize from "./database.js";
// import cors from "cors";

// Import Routers
import productRouter from "./routes/Product.js";
import authRouter from "./routes/auth.js";
import salesRouter from "./routes/Sales.js"
import "./models/relations.js"
import path from "path"
import { fileURLToPath } from "url";
import purchasedReceiptRouter from "./routes/PurchasedReceipt.js";

const app = express();
const PORT = 3000;

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

app.use("/uploads", express.static(path.join(__dirname, "uploads")));
app.use(express.json());

// Connect Routes
app.use(productRouter);
app.use(authRouter);
app.use(salesRouter);
app.use(purchasedReceiptRouter)

// DB connection Test
sequelize.authenticate()
    .then(() => console.log("MySQL Connected✅"))
    .catch((e) => console.log(e));

app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running at port ${PORT}`);
})