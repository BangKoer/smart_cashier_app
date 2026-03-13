import express from "express";
import multer from "multer";
import path from "path";
import PurchasedReceipt from "../models/PurchasedReceipt.js";
import PurchasedReceiptItem from "../models/PurchasedReceiptItem.js";
import PurchasedReceiptFile from "../models/PurchasedReceiptFile.js";
import Supplier from "../models/supplier.js";

const purchasedReceiptRouter = express.Router();

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, "server/uploads/invoices"),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    const name = `${Date.now()}-${Math.random().toString(36).slice(2)}${ext}`;
    cb(null, name);
  },
});
const upload = multer({ storage });

// CREATE receipt + items
purchasedReceiptRouter.post("/api/purchased-receipts", async (req, res) => {
  try {
    const { id_supplier, receipt_no, receipt_date, notes, items = [] } = req.body;

    const receipt = await PurchasedReceipt.create({
      id_supplier,
      receipt_no,
      receipt_date,
      notes,
      total_amount: 0,
    });

    let total = 0;
    for (const it of items) {
      const qty = Number(it.quantity || 0);
      const unit = Number(it.unit_cost || 0);
      const sub = qty * unit;
      total += sub;

      await PurchasedReceiptItem.create({
        id_purchase_receipt: receipt.id,
        id_product: it.id_product ?? null,
        item_name: it.item_name ?? null,
        quantity: qty,
        unit_cost: unit,
        sub_total: sub,
      });
    }

    await PurchasedReceipt.update({ total_amount: total }, { where: { id: receipt.id } });

    res.json({ msg: "ok", id: receipt.id });
  } catch (e) {
    res.status(500).json({ msg: e.message });
  }
});

// LIST receipts
purchasedReceiptRouter.get("/api/purchased-receipts", async (req, res) => {
  try {
    const rows = await PurchasedReceipt.findAll({
      include: [{ model: Supplier, required: false }],
      order: [["receipt_date", "DESC"]],
    });
    res.json(rows);
  } catch (e) {
    res.status(500).json({ msg: e.message });
  }
});

// DETAIL receipt
purchasedReceiptRouter.get("/api/purchased-receipts/:id", async (req, res) => {
  try {
    const receipt = await PurchasedReceipt.findByPk(req.params.id);
    if (!receipt) return res.status(404).json({ msg: "not found" });

    const items = await PurchasedReceiptItem.findAll({
      where: { id_purchase_receipt: receipt.id },
    });
    const files = await PurchasedReceiptFile.findAll({
      where: { id_purchase_receipt: receipt.id },
    });

    res.json({ receipt, items, files });
  } catch (e) {
    res.status(500).json({ msg: e.message });
  }
});

// UPLOAD invoice image
purchasedReceiptRouter.post("/api/purchased-receipts/:id/files", upload.single("file"), async (req, res) => {
  try {
    const file = req.file;
    if (!file) return res.status(400).json({ msg: "no file" });

    const created = await PurchasedReceiptFile.create({
      id_purchase_receipt: req.params.id,
      file_path: `/uploads/invoices/${file.filename}`,
      original_name: file.originalname,
      mime_type: file.mimetype,
      file_size: file.size,
    });

    res.json({ msg: "ok", file: created });
  } catch (e) {
    res.status(500).json({ msg: e.message });
  }
});

export default purchasedReceiptRouter;
