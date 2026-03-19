import express from "express";
import multer from "multer";
import path from "path";
import PurchasedReceipt from "../models/PurchasedReceipt.js";
import PurchasedReceiptItem from "../models/PurchasedReceiptItem.js";
import PurchasedReceiptFile from "../models/PurchasedReceiptFile.js";
import Product from "../models/Product.js";
import Supplier from "../models/supplier.js";
import auth from "../middlewares/auth.js";
import fs from "fs";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const uploadDir = path.join(__dirname, "..", "uploads", "invoices");

const purchasedReceiptRouter = express.Router();

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    const name = `${Date.now()}-${Math.random().toString(36).slice(2)}${ext}`;
    cb(null, name);
  },
});
const upload = multer({ storage });

// CREATE receipt + items
purchasedReceiptRouter.post("/api/purchased-receipts", auth, async (req, res) => {
  let t = await PurchasedReceipt.sequelize.transaction();
  try {

    const { id_supplier, receipt_no, receipt_date, note, items = [] } = req.body;

    if (!receipt_date) {
      await t.rollback();
      return res.status(400).json({ msg: "receipt_date required" });
    }

    if (!Array.isArray(items)) {
      await t.rollback()
      return res.status(400).json({ msg: "items must be array" });
    }

    const receipt = await PurchasedReceipt.create({
      id_supplier,
      receipt_no,
      receipt_date,
      note,
      total_cost: 0,
    }, { transaction: t });

    let total = 0;
    for (const it of items) {
      const qty = Number(it.qty || 0);
      const unit = Number(it.unit_cost || 0);
      if (qty < 0 || unit < 0) {
        await t.rollback();
        return res.status(400).json({ msg: "invalid item quantity/unit_cost" })
      }

      const sub = qty * unit;
      total += sub;

      await PurchasedReceiptItem.create({
        id_purchased_receipt: receipt.id,
        id_product: it.id_product ?? null,
        id_product_unit: it.id_product_unit,
        qty: qty,
        unit_cost: unit,
        sub_total: sub,
      }, { transaction: t });
    }

    await PurchasedReceipt.update({ total_cost: total }, { where: { id: receipt.id }, transaction: t });

    await t.commit();
    res.status(201).json({ msg: "Receipt Created Successfully", id: receipt.id });
  } catch (e) {
    await t.rollback();
    res.status(500).json({ msg: e.message });
  }
});

// LIST receipts
purchasedReceiptRouter.get("/api/purchased-receipts", auth, async (req, res) => {
  try {
    const rows = await PurchasedReceipt.findAll({
      include: [{ model: Supplier, as: "supplier", required: false }],
      order: [["receipt_date", "DESC"]],
    });
    res.json(rows);
  } catch (e) {
    res.status(500).json({ msg: e.message });
  }
});

// DETAIL receipt
purchasedReceiptRouter.get("/api/purchased-receipts/:id", auth, async (req, res) => {
  try {
    const receipt = await PurchasedReceipt.findByPk(req.params.id);
    if (!receipt) return res.status(404).json({ msg: "not found" });

    const supplier = receipt.id_supplier
      ? await Supplier.findByPk(receipt.id_supplier)
      : null;

    const items = await PurchasedReceiptItem.findAll({
      where: { id_purchased_receipt: receipt.id },
      include: [
        {
          model: Product,
          as: "product",
          attributes: ["id", "product_name"],
        },
      ],
    });
    const files = await PurchasedReceiptFile.findAll({
      where: { id_purchased_receipt: receipt.id },
    });

    const receiptData = receipt.toJSON();
    if (supplier) {
      receiptData.supplier = supplier;
    }
    res.json({ receipt: receiptData, items, files });
  } catch (e) {
    res.status(500).json({ msg: e.message });
  }
});

// UPLOAD invoice image
purchasedReceiptRouter.post("/api/purchased-receipts/:id/files", auth, upload.single("file"), async (req, res) => {
  try {
    const file = req.file;
    if (!file) return res.status(400).json({ msg: "no file" });

    const created = await PurchasedReceiptFile.create({
      id_purchased_receipt: req.params.id,
      file_path: `/uploads/invoices/${file.filename}`,
      file_name: file.originalname,
      uploaded_at: new Date(),
    });

    res.json({ msg: "ok", file: created });
  } catch (e) {
    res.status(500).json({ msg: e.message });
  }
});

// UPDATE receipt
purchasedReceiptRouter.put("/api/purchased-receipts/:id", auth, async (req, res) => {
  let t = await PurchasedReceipt.sequelize.transaction();
  try {
    const { id_supplier, receipt_no, receipt_date, note, items = [] } = req.body;
    const receipt = await PurchasedReceipt.findByPk(req.params.id);
    if (!receipt) return res.status(404).json({ msg: "Receipt Not Found!" });

    await PurchasedReceipt.update(
      { id_supplier, receipt_no, receipt_date, note },
      { where: { id: receipt.id }, transaction: t }
    );

    await PurchasedReceiptItem.destroy({
      where: { id_purchased_receipt: receipt.id },
      transaction: t
    });

    let total = 0;
    for (const item of items) {
      const qty = Number(item.qty || 0);
      const unit = Number(item.unit_cost || 0);
      if (qty < 0 || unit < 0) {
        await t.rollback();
        return res.status(400).json({ msg: "invalid item quantity/unit_cost" });
      }
      const sub = qty * unit;
      total += sub;

      await PurchasedReceiptItem.create({
        id_purchased_receipt: receipt.id,
        id_product: item.id_product ?? null,
        id_product_unit: item.id_product_unit,
        qty: qty,
        unit_cost: unit,
        sub_total: sub
      }, { transaction: t });
    }


    await PurchasedReceipt.update(
      { total_cost: total },
      { where: { id: receipt.id }, transaction: t }
    );

    await t.commit();

    return res.status(201).json({ msg: "Receipt Updated Successfully", });

  } catch (e) {
    await t.rollback();
    return res.status(500).json({ msg: e.message });
  }
});

// DELETE receipt
purchasedReceiptRouter.delete("/api/purchased-receipts/:id", auth, async (req, res) => {
  let t = await PurchasedReceipt.sequelize.transaction();
  try {
    const receipt = await PurchasedReceipt.findByPk(req.params.id);
    if (!receipt) return res.status(404).json({ msg: "Receipt not found" });

    await PurchasedReceiptItem.destroy({ where: { id_purchased_receipt: receipt.id }, transaction: t });

    await PurchasedReceiptFile.destroy({ where: { id_purchased_receipt: receipt.id }, transaction: t });

    await PurchasedReceipt.destroy({ where: { id: receipt.id }, transaction: t });

    await t.commit();

    return res.status(201).json({
      msg: "Receipt Deleted Successfully",
    });

  } catch (e) {
    await t.rollback();
    return res.status(500).json({ msg: e.message });
  }
});

// DELETE Physical File
purchasedReceiptRouter.delete("/api/purchased-receipts/:id/files/:fileId", auth, async (req, res) => {
  try {
    const file = await PurchasedReceiptFile.findByPk(req.params.fileId);
    if (!file) return res.status(404).json({ msg: "File Not Found" });

    const relPath = file.file_path.replace(/^\/+/, "");
    const fullPath = path.join("server", relPath);
    if (fs.existsSync(fullPath)) fs.unlinkSync(fullPath);

    await PurchasedReceiptFile.destroy({ where: { id: file.id } });

    return res.status(201).json({ msg: "File Deleted Successfully" })
  } catch (e) {
    return res.status(500).json({ msg: e.message });
  }
})

export default purchasedReceiptRouter;
