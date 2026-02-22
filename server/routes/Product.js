import express from "express"
import Product from "../models/Product.js"
import ProductUnit from "../models/ProductUnit.js";
import Category from "../models/category.js";
import auth from "../middlewares/auth.js";

const productRouter = express.Router();

// Product CRUD Endpoints
productRouter.post('/api/products', auth, async (req, res) => {
    let t = await Product.sequelize.transaction();
    try {
        const {
            barcode,
            product_name,
            stock,
            purchased_price,
            id_category,
            units
        } = req.body;

        if (!barcode || !product_name || purchased_price === undefined || stock === undefined || !id_category) {
            await t.rollback();
            return res.status(400).json({
                msg: "Missing required fields",
                required: ["barcode", "product_name", "stock", "purchased_price", "id_category", "units"]
            });
        }

        if (!Array.isArray(units) || units.length === 0) {
            await t.rollback();
            return res.status(400).json({
                msg: "Units must be a non-empty array"
            });
        }

        const existingProduct = await Product.findOne({ where: { barcode } });
        if (existingProduct) {
            await t.rollback();
            return res.status(409).json({
                msg: "Barcode already exists"
            });
        }

        const category = await Category.findByPk(id_category);
        if (!category) {
            await t.rollback();
            return res.status(404).json({
                msg: "Category not found"
            });
        }

        const product = await Product.create({
            barcode,
            product_name,
            stock: Number(stock),
            purchased_price: Number(purchased_price),
            id_category,
        }, { transaction: t });

        const unitPayload = units.map((unit) => ({
            id_product: product.id,
            name_unit: unit.name_unit ?? unit.nameUnit,
            price: Number(unit.price),
            conversion: Number(unit.conversion ?? 1),
        }));

        const hasInvalidUnit = unitPayload.some(
            (unit) => !unit.name_unit || Number.isNaN(unit.price) || Number.isNaN(unit.conversion)
        );

        if (hasInvalidUnit) {
            await t.rollback();
            return res.status(400).json({
                msg: "Invalid units payload"
            });
        }

        await ProductUnit.bulkCreate(unitPayload, { transaction: t });
        await t.commit();

        const createdProduct = await Product.findByPk(product.id, {
            include: [
                { model: ProductUnit, as: "units" },
                { model: Category, as: "category", attributes: ["name"] }
            ]
        });

        return res.status(201).json({
            msg: "Product created successfully",
            data: createdProduct
        });
    } catch (e) {
        if (t) await t.rollback();
        return res.status(500).json({
            error: e.message
        });
    }
});

productRouter.put('/api/products/:id', auth, async (req, res) => {
    let t = await Product.sequelize.transaction();
    try {
        const { id } = req.params;
        const {
            barcode,
            product_name,
            stock,
            purchased_price,
            id_category,
            units
        } = req.body;

        if (!barcode || !product_name || purchased_price === undefined || stock === undefined || !id_category) {
            await t.rollback();
            return res.status(400).json({
                msg: "Missing required fields",
                required: ["barcode", "product_name", "stock", "purchased_price", "id_category", "units"]
            });
        }

        if (!Array.isArray(units) || units.length === 0) {
            await t.rollback();
            return res.status(400).json({
                msg: "Units must be a non-empty array"
            });
        }

        const product = await Product.findByPk(id);
        if (!product) {
            await t.rollback();
            return res.status(404).json({
                msg: "Product not found"
            });
        }

        const existingBarcode = await Product.findOne({ where: { barcode } });
        if (existingBarcode && existingBarcode.id !== Number(id)) {
            await t.rollback();
            return res.status(409).json({
                msg: "Barcode already exists"
            });
        }

        const category = await Category.findByPk(id_category);
        if (!category) {
            await t.rollback();
            return res.status(404).json({
                msg: "Category not found"
            });
        }

        const unitPayload = units.map((unit) => ({
            id_product: Number(id),
            name_unit: unit.name_unit ?? unit.nameUnit,
            price: Number(unit.price),
            conversion: Number(unit.conversion ?? 1),
        }));

        const hasInvalidUnit = unitPayload.some(
            (unit) => !unit.name_unit || Number.isNaN(unit.price) || Number.isNaN(unit.conversion)
        );

        if (hasInvalidUnit) {
            await t.rollback();
            return res.status(400).json({
                msg: "Invalid units payload"
            });
        }

        await Product.update(
            {
                barcode,
                product_name,
                stock: Number(stock),
                purchased_price: Number(purchased_price),
                id_category,
            },
            {
                where: { id: Number(id) },
                transaction: t,
            }
        );

        // Simpler and safer for now: replace all units on every edit.
        await ProductUnit.destroy({
            where: { id_product: Number(id) },
            transaction: t,
        });

        await ProductUnit.bulkCreate(unitPayload, { transaction: t });

        await t.commit();

        const updatedProduct = await Product.findByPk(id, {
            include: [
                { model: ProductUnit, as: "units" },
                { model: Category, as: "category", attributes: ["name"] }
            ]
        });

        return res.status(200).json({
            msg: "Product updated successfully",
            data: updatedProduct
        });
    } catch (e) {
        if (t) await t.rollback();
        return res.status(500).json({
            error: e.message
        });
    }
});

productRouter.get('/api/products', auth, async (req, res) => {
    try {
        const products = await Product.findAll(
            {
                include: [
                    { model: ProductUnit, as: "units" },
                    { model: Category, as: "category", attributes: ["name"] }
                ]
            }
        );
        res.json(products);
    } catch (e) {
        res.status(500).json({
            error: e.message
        })
    }
})

productRouter.get('/api/product/:barcode', auth, async (req, res) => {
    try {
        const { barcode } = req.params;
        const products = await Product.findOne(
            {
                where: { barcode },
                include: [
                    { model: ProductUnit, as: "units" },
                    { model: Category, as: "category", attributes: ["name"] }
                ]
            }
        );

        if (!products) {
            return res.status(404).json({
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

productRouter.delete('/api/product/:id', auth, async (req, res) => {
    let t = await Product.sequelize.transaction();
    try {
        const { id } = req.params;
        const product = await Product.findByPk(id);
        if (!product) {
            await t.rollback();
            return res.status(404).json({
                msg: "Product not found"
            });
        }

        // Delete the product unit first
        await ProductUnit.destroy({
            where: { id_product: Number(id) },
            transaction: t,
        });

        await Product.destroy({
            where: { id: Number(id) },
            transaction: t,
        });

        await t.commit();
        return res.status(200).json({
            msg: "Product deleted successfully"
        });
    } catch (e) {
        if (t) await t.rollback();
        return res.status(500).json({
            error: e.message
        });
    }
});

// Categories CRUD endpoints
productRouter.get('/api/categories', auth, async (req, res) => {
    try {
        const categories = await Category.findAll();
        res.json(categories);
    } catch (e) {
        res.status(500).json({
            error: e.message
        })
    }
})

productRouter.get('/api/categories/:id', auth, async (req, res) => {
    try {
        const { id } = req.params;
        const category = await Category.findByPk(id);
        if (!category) {
            return res.status(404).json({
                msg: "Category not found"
            });
        }
        return res.status(200).json(category);
    } catch (e) {
        return res.status(500).json({
            error: e.message
        });
    }
});

productRouter.post('/api/categories', auth, async (req, res) => {
    try {
        const { name } = req.body;
        const categoryName = String(name ?? "").trim();

        if (!categoryName) {
            return res.status(400).json({
                msg: "Missing required fields",
                required: ["name"]
            });
        }

        const existingCategory = await Category.findOne({
            where: { name: categoryName }
        });

        if (existingCategory) {
            return res.status(409).json({
                msg: "Category already exists"
            });
        }

        const category = await Category.create({
            name: categoryName
        });

        return res.status(201).json({
            msg: "Category created successfully",
            data: category
        });
    } catch (e) {
        return res.status(500).json({
            error: e.message
        });
    }
});

productRouter.put('/api/categories/:id', auth, async (req, res) => {
    try {
        const { id } = req.params;
        const { name } = req.body;
        const categoryName = String(name ?? "").trim();

        if (!categoryName) {
            return res.status(400).json({
                msg: "Missing required fields",
                required: ["name"]
            });
        }

        const category = await Category.findByPk(id);
        if (!category) {
            return res.status(404).json({
                msg: "Category not found"
            });
        }

        const existingCategory = await Category.findOne({
            where: { name: categoryName }
        });
        if (existingCategory && Number(existingCategory.id) !== Number(id)) {
            return res.status(409).json({
                msg: "Category already exists"
            });
        }

        await Category.update(
            { name: categoryName },
            { where: { id: Number(id) } }
        );

        const updatedCategory = await Category.findByPk(id);
        return res.status(200).json({
            msg: "Category updated successfully",
            data: updatedCategory
        });
    } catch (e) {
        return res.status(500).json({
            error: e.message
        });
    }
});

productRouter.delete('/api/categories/:id', auth, async (req, res) => {
    try {
        const { id } = req.params;

        const category = await Category.findByPk(id);
        if (!category) {
            return res.status(404).json({
                msg: "Category not found"
            });
        }

        const usedByProduct = await Product.count({
            where: { id_category: Number(id) }
        });
        if (usedByProduct > 0) {
            return res.status(409).json({
                msg: "Category is still used by products"
            });
        }

        await Category.destroy({
            where: { id: Number(id) }
        });

        return res.status(200).json({
            msg: "Category deleted successfully"
        });
    } catch (e) {
        return res.status(500).json({
            error: e.message
        });
    }
});


export default productRouter;
