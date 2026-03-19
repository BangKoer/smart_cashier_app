import express from "express";
import Supplier from "../models/Supplier.js";
import PurchasedReceipt from "../models/PurchasedReceipt.js";
import auth from "../middlewares/auth.js";

const supplierRouter = express.Router();

// Create supplier
supplierRouter.post("/api/suppliers", auth, async (req, res) => {
  try {
    const supplierName = String(req.body.supplier_name ?? req.body.name ?? "").trim();
    const company = req.body.company ?? null;
    const phone = req.body.phone ?? null;
    const address = String(req.body.address ?? "").trim();

    if (!supplierName || !address) {
      return res.status(400).json({
        msg: "Missing required fields",
        required: ["supplier_name", "address"],
      });
    }

    const created = await Supplier.create({
      supplier_name: supplierName,
      company,
      phone,
      address,
    });

    return res.status(201).json({ msg: "Supplier created", data: created });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

// List suppliers
supplierRouter.get("/api/suppliers", auth, async (req, res) => {
  try {
    const rows = await Supplier.findAll({ order: [["id", "DESC"]] });
    return res.json(rows);
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

// Get supplier by id
supplierRouter.get("/api/suppliers/:id", auth, async (req, res) => {
  try {
    const supplier = await Supplier.findByPk(req.params.id);
    if (!supplier) {
      return res.status(404).json({ msg: "Supplier not found" });
    }
    return res.json(supplier);
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

// Update supplier
supplierRouter.put("/api/suppliers/:id", auth, async (req, res) => {
  try {
    const supplier = await Supplier.findByPk(req.params.id);
    if (!supplier) {
      return res.status(404).json({ msg: "Supplier not found" });
    }

    const supplierName = String(req.body.supplier_name ?? req.body.name ?? "").trim();
    const company = req.body.company ?? null;
    const phone = req.body.phone ?? null;
    const address = String(req.body.address ?? "").trim();

    if (!supplierName || !address) {
      return res.status(400).json({
        msg: "Missing required fields",
        required: ["supplier_name", "address"],
      });
    }

    await Supplier.update(
      { supplier_name: supplierName, company, phone, address },
      { where: { id: Number(req.params.id) } }
    );

    const updated = await Supplier.findByPk(req.params.id);
    return res.status(200).json({ msg: "Supplier updated", data: updated });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

// Delete supplier
supplierRouter.delete("/api/suppliers/:id", auth, async (req, res) => {
  try {
    const supplier = await Supplier.findByPk(req.params.id);
    if (!supplier) {
      return res.status(404).json({ msg: "Supplier not found" });
    }

    const used = await PurchasedReceipt.count({
      where: { id_supplier: Number(req.params.id) },
    });
    if (used > 0) {
      return res.status(409).json({
        msg: "Supplier is used by purchase receipts",
      });
    }

    await Supplier.destroy({ where: { id: Number(req.params.id) } });
    return res.status(200).json({ msg: "Supplier deleted" });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

export default supplierRouter;
