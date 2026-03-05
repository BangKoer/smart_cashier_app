import express from "express";
import auth from "../middlewares/auth.js";
import Sales from "../models/sales.js";
import SaleItem from "../models/SaleItem.js";
import Product from "../models/Product.js";
import ProductUnit from "../models/ProductUnit.js";

const salesRoute = express.Router();

const roundTo = (value, fractionDigits) =>
    Number(Number(value).toFixed(fractionDigits));

const normalizeQty = (value) => roundTo(Number(value), 3);
const normalizeMoney = (value) => roundTo(Number(value), 2);
const normalizePercent = (value) => roundTo(Number(value), 1);

const buildSaleItemPayload = (rawItem, salesId) => {
    const quantity = normalizeQty(rawItem.quantity);
    const unitPriceSnapshot = normalizeMoney(
        rawItem.unit_price_snapshot ??
        rawItem.unit_price ??
        rawItem.price ??
        ((Number(rawItem.quantity) > 0)
            ? Number(rawItem.sub_total) / Number(rawItem.quantity)
            : NaN)
    );

    const discountPercent =
        rawItem.discount_percent === null || rawItem.discount_percent === undefined
            ? null
            : normalizePercent(rawItem.discount_percent);

    const discountAmount =
        rawItem.discount_amount === null || rawItem.discount_amount === undefined
            ? null
            : normalizeMoney(rawItem.discount_amount);

    const subTotal = normalizeMoney(rawItem.sub_total);

    return {
        id_sales: Number(salesId),
        id_product: rawItem.id_product,
        id_product_unit: rawItem.id_product_unit,
        quantity,
        unit_price_snapshot: unitPriceSnapshot,
        discount_percent: discountPercent,
        discount_amount: discountAmount,
        sub_total: subTotal,
    };
};

const isInvalidSaleItem = (item) => {
    if (
        !item.id_product ||
        !item.id_product_unit ||
        Number.isNaN(item.quantity) ||
        Number.isNaN(item.unit_price_snapshot) ||
        Number.isNaN(item.sub_total)
    ) {
        return true;
    }

    if (item.quantity <= 0 || item.unit_price_snapshot < 0 || item.sub_total < 0) {
        return true;
    }

    if (
        item.discount_percent !== null &&
        (Number.isNaN(item.discount_percent) ||
            item.discount_percent < 0 ||
            item.discount_percent > 100)
    ) {
        return true;
    }

    const lineTotalBeforeDiscount = normalizeMoney(item.unit_price_snapshot * item.quantity);
    const effectiveDiscountAmount = item.discount_amount ?? normalizeMoney(
        lineTotalBeforeDiscount * ((item.discount_percent ?? 0) / 100)
    );

    if (Number.isNaN(effectiveDiscountAmount) || effectiveDiscountAmount < 0) {
        return true;
    }

    if (effectiveDiscountAmount > lineTotalBeforeDiscount) {
        return true;
    }

    const expectedSubtotal = normalizeMoney(lineTotalBeforeDiscount - effectiveDiscountAmount);
    if (Math.abs(item.sub_total - expectedSubtotal) > 0.01) {
        return true;
    }

    return false;
};

// Add Sales and Sale Item
salesRoute.post('/api/sales', auth, async (req, res) => {
    let t = await Sales.sequelize.transaction();
    try {
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

        const normalizedTotalPrice = normalizeMoney(total_price);
        const normalizedTotalPayout = normalizeMoney(total_payout ?? total_price);
        if (Number.isNaN(normalizedTotalPrice) || Number.isNaN(normalizedTotalPayout)) {
            await t.rollback();
            return res.status(400).json({
                msg: "Invalid total_price/total_payout",
            });
        }

        let sales = await Sales.create({
            id_user,
            total_price: normalizedTotalPrice,
            total_payout: normalizedTotalPayout,
            payment_method,
            payment_status,
            customer_name,
        }, { transaction: t });

        const saleItems = items.map((item) => buildSaleItemPayload(item, sales.id));
        const hasInvalidItems = saleItems.some(isInvalidSaleItem);

        if (hasInvalidItems) {
            await t.rollback();
            return res.status(400).json({
                msg: "Invalid sale items payload"
            });
        }

        await SaleItem.bulkCreate(saleItems, { transaction: t });

        const qtyByProduct = new Map();
        for (const item of saleItems) {
            const pid = Number(item.id_product);
            const prev = qtyByProduct.get(pid) ?? 0;
            qtyByProduct.set(pid, prev + Number(item.quantity));
        }

        for (const [productId, soldQty] of qtyByProduct.entries()) {
            const product = await Product.findByPk(productId, { transaction: t })
            if (!product) {
                await t.rollback();
                return res.status(404).json({ msg: `Product #${productId} not found` })
            }

            const newStock = Number(product.stock) - Number(soldQty);
            await Product.update(
                { stock: newStock },
                { where: { id: productId }, transaction: t }
            );
        }

        await t.commit();

        return res.status(200).json({
            msg: "Transaction Successfull",
            data: sales,
        });

    } catch (e) {
        if (t) await t.rollback();
        return res.status(500).json({ error: e.message });
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

        const saleItems = items.map((item) => buildSaleItemPayload(item, id));
        const hasInvalidItems = saleItems.some(isInvalidSaleItem);

        if (hasInvalidItems) {
            await t.rollback();
            return res.status(400).json({
                msg: "Invalid sale items payload"
            });
        }

        const normalizedTotalPrice = normalizeMoney(total_price);
        const normalizedTotalPayout = normalizeMoney(total_payout ?? total_price);
        if (Number.isNaN(normalizedTotalPrice) || Number.isNaN(normalizedTotalPayout)) {
            await t.rollback();
            return res.status(400).json({
                msg: "Invalid total_price/total_payout",
            });
        }

        const existingItems = await SaleItem.findAll({
            where: { id_sales: Number(id) },
            transaction: t,
        })


        await Sales.update(
            {
                id_user,
                total_price: normalizedTotalPrice,
                total_payout: normalizedTotalPayout,
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

        
        const oldMap = new Map();
        for (const it of existingItems) {
            const pid = Number(it.id_product);
            oldMap.set(pid, (oldMap.get(pid) ?? 0) + Number(it.quantity))
        }

        const newMap = new Map();
        for (const it of saleItems) {
            const pid = Number(it.id_product);
            newMap.set(pid, (newMap.get(pid) ?? 0) + Number(it.quantity))
        }

        const productIds = new Set([...oldMap.keys(), ...newMap.keys()]);
        for (const productId of productIds) {
            const oldQty = oldMap.get(productId) ?? 0;
            const newQty = newMap.get(productId) ?? 0;
            const delta = newQty - oldQty;

            if (delta === 0) continue;
            const product = await Product.findByPk(productId, { transaction: t });

            if (!product) {
                await t.rollback();
                return res.status(404).json({ msg: `Product #${productId} not found` });
            }

            const newStock = Number(product.stock) - Number(delta);
            await Product.update(
                { stock: newStock },
                { where: { id: productId }, transaction: t },
            )
        };

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
