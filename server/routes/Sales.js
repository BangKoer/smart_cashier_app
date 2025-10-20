import express from "express";
import auth from "../middlewares/auth";

const salesRoute = express.Router();

// Add Sales
salesRoute.post('/api/sales',auth, (req,res) => {
    try {
        const { id_user, total_price, payment_method, payment_status, customer_name } = req.body;
        
    } catch (e) {
        res.status(500).json({error : e.message});
    }
})