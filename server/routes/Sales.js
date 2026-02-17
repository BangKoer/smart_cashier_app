import express from "express";
import auth from "../middlewares/auth.js";
import Sales from "../models/sales.js";
import SaleItem from "../models/SaleItem.js";
import Product from "../models/Product.js";
import ProductUnit from "../models/ProductUnit.js";

const salesRoute = express.Router();

// Add Sales and Sale Item
salesRoute.post('/api/sales', auth, async (req, res) => {
    let t = await Sales.sequelize.transaction();
    try {
        const { id_user, total_price, total_payout, payment_method, payment_status, customer_name, items } = req.body;
        let sales = await Sales.create({
            id_user,
            total_price,
            total_payout: total_payout ?? total_price,
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

// Update Sales and Sale Items
salesRoute.put('/api/sales/:id', auth, async (req, res) => {
    let t = await Sales.sequelize.transaction();
    try {
        const { id } = req.params;
        const { id_user, total_price, total_payout, payment_method, payment_status, customer_name, items } = req.body;

        if (!id_user || total_price === undefined || !payment_method || !payment_status) {
            await t.rollback();
            return res.status(400).json({
                msg: "Missing required fields",
                required: ["id_user", "total_price", "payment_method", "payment_status", "items"]
            });
        }

        if (!Array.isArray(items) || items.length === 0) {
            await t.rollback();
            return res.status(400).json({
                msg: "Items must be a non-empty array"
            });
        }

        const sales = await Sales.findByPk(id);
        if (!sales) {
            await t.rollback();
            return res.status(404).json({
                msg: "Sales not found"
            });
        }

        const saleItems = items.map(item => ({
            id_sales: Number(id),
            id_product: item.id_product,
            id_product_unit: item.id_product_unit,
            quantity: item.quantity,
            sub_total: item.sub_total,
        }));

        const hasInvalidItems = saleItems.some(
            (item) =>
                !item.id_product ||
                !item.id_product_unit ||
                Number.isNaN(Number(item.quantity)) ||
                Number.isNaN(Number(item.sub_total))
        );

        if (hasInvalidItems) {
            await t.rollback();
            return res.status(400).json({
                msg: "Invalid sale items payload"
            });
        }

        await Sales.update(
            {
                id_user,
                total_price,
                total_payout: total_payout ?? total_price,
                payment_method,
                payment_status,
                customer_name,
            },
            {
                where: { id: Number(id) },
                transaction: t,
            }
        );

        await SaleItem.destroy({
            where: { id_sales: Number(id) },
            transaction: t,
        });

        await SaleItem.bulkCreate(saleItems, { transaction: t });

        await t.commit();

        const updatedSales = await Sales.findByPk(id, {
            include: [
                {
                    model: SaleItem,
                    as: "items",
                    include: [
                        { model: Product, as: "product", attributes: ["id", "product_name"] },
                        { model: ProductUnit, as: "unit", attributes: ["id", "name_unit", "price"] },
                    ],
                },
            ],
        });

        return res.status(200).json({
            msg: "Sales updated successfully",
            data: updatedSales,
        });
    } catch (e) {
        if (t) await t.rollback();
        return res.status(500).json({ error: e.message });
    }
});

// Get all sales with sale items
salesRoute.get('/api/sales', auth, async (req, res) => {
    try {
        const sales = await Sales.findAll({
            include: [
                {
                    model: SaleItem,
                    as: "items",
                    include: [
                        { model: Product, as: "product", attributes: ["id", "product_name"] },
                        { model: ProductUnit, as: "unit", attributes: ["id", "name_unit", "price"] },
                    ],
                },
            ],
            order: [["id", "DESC"]],
        });

        return res.status(200).json(sales);
    } catch (e) {
        return res.status(500).json({ error: e.message });
    }
});

// Get sales detail by id
salesRoute.get('/api/sales/:id', auth, async (req, res) => {
    try {
        const { id } = req.params;
        const sales = await Sales.findByPk(id, {
            include: [
                {
                    model: SaleItem,
                    as: "items",
                    include: [
                        { model: Product, as: "product", attributes: ["id", "product_name"] },
                        { model: ProductUnit, as: "unit", attributes: ["id", "name_unit", "price"] },
                    ],
                },
            ],
        });

        if (!sales) {
            return res.status(404).json({
                msg: "Sales not found",
            });
        }

        return res.status(200).json(sales);
    } catch (e) {
        return res.status(500).json({ error: e.message });
    }
});

// Delete sales and its sale items
salesRoute.delete('/api/sales/:id', auth, async (req, res) => {
    let t = await Sales.sequelize.transaction();
    try {
        const { id } = req.params;
        const salesId = Number(id);

        if (Number.isNaN(salesId)) {
            await t.rollback();
            return res.status(400).json({
                msg: "Invalid sales id",
            });
        }

        const sales = await Sales.findByPk(salesId, { transaction: t });
        if (!sales) {
            await t.rollback();
            return res.status(404).json({
                msg: "Sales not found",
            });
        }

        await SaleItem.destroy({
            where: { id_sales: salesId },
            transaction: t,
        });

        await Sales.destroy({
            where: { id: salesId },
            transaction: t,
        });

        await t.commit();
        return res.status(200).json({
            msg: "Sales deleted successfully",
            id: salesId,
        });
    } catch (e) {
        if (t) await t.rollback();
        return res.status(500).json({ error: e.message });
    }
});

export default salesRoute;
