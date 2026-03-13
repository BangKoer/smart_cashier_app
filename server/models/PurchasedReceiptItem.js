import { DataTypes } from "sequelize";
import sequelize from "../database.js";

const PurchasedReceiptItem = sequelize.define(
    "PurchasedReceiptItem", {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    id_purchase_receipt: { type: DataTypes.INTEGER, allowNull: false },
    id_product: { type: DataTypes.INTEGER, allowNull: true },
    item_name: { type: DataTypes.STRING(255), allowNull: true },
    quantity: { type: DataTypes.DECIMAL(10, 2), allowNull: false, defaultValue: 1 },
    unit_cost: { type: DataTypes.DECIMAL(10, 2), allowNull: false, defaultValue: 0 },
    sub_total: { type: DataTypes.DECIMAL(10, 2), allowNull: false, defaultValue: 0 },
}, {
    tableName: "tb_purchased_receipt_item",
    timestamps: false,
});

export default PurchasedReceiptItem;