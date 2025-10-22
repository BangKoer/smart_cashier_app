import express from "express";
import auth from "../middlewares/auth.js";
import Sales from "../models/sales.js";
import SaleItem from "../models/SaleItem.js";

const salesRoute = express.Router();

// Add Sales and Sale Item
salesRoute.post('/api/sales', auth, async (req, res) => {
    let t = await Sales.sequelize.transaction();
    try {
        const { id_user, total_price, payment_method, payment_status, customer_name, items } = req.body;
        let sales = await Sales.create({
            id_user,
            total_price,
            payment_method,
            payment_status,
            customer_name,
        }, { transaction: t });

        if (sales && items && Array.isArray(items)) {
            // for (const item of items) {
            //     await SaleItem.create({
            //         id_sales: sales.id,
            //         id_product: item.id_product,
            //         id_product_unit: item.id_product_unit,
            //         quantity: item.quantity,
            //         sub_total: item.sub_total,
            //     });
            // }
            const saleItems = items.map(item => ({
                id_sales: sales.id,             // foreign key ke tb_sales
                id_product: item.id_product,
                id_product_unit: item.id_product_unit,
                quantity: item.quantity,
                sub_total: item.sub_total,
            }));

            await SaleItem.bulkCreate(saleItems, { transaction: t });
        }

        await t.commit();

        res.status(200).json({
            msg: "Transaction Successfull",
            data: sales,
        });

    } catch (e) {
        if (t) await t.rollback();
        res.status(500).json({ error: e.message });
    }
})

export default salesRoute;