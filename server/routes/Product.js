import express from "express"
import Product from "../models/Product.js"
import ProductUnit from "../models/ProductUnit.js";

const productRouter = express.Router();

productRouter.get('/api/products', async (req, res) => {
    try {
        const products = await Product.findAll(
            {include : [{model: ProductUnit}]}
        );
        res.json(products);
    } catch (e) {
        res.status(500).json({
            error: e.message
        })
    }
})

productRouter.get('/api/product/:barcode', async (req, res) => {
    try {
        const { barcode } = req.params;
        const products = await Product.findOne(
            {
                where: { barcode },
                include: [{model: ProductUnit}]
            }
        );

        if (!products) {
            res.status(404).json({
                msg: "No Product Available"
            })
        }

        res.json(products);
    } catch (e) {
        res.status(500).json({
            error: e.message
        })
    }
});

export default productRouter;