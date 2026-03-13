import { DataTypes } from "sequelize";
import sequelize from "../database.js";

const PurchasedReceipt = sequelize.define(
    "PurchasedReceipt", {
    id: {
        type: DataTypes.INTEGER,
        autoIncrement: true,
        primaryKey: true,
        allowNull: false,
    },
    id_supplier: {
        type: DataTypes.INTEGER,
        allowNull: true,
    },
    receipt_no: {
        type: DataTypes.STRING(255),
        allowNull: true
    },
    receipt_date: {
        type: DataTypes.DATE,
        allowNull: false,
    },
    total_cost: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: false,
        defaultValue: 0
    },
    note: {
        type: DataTypes.TEXT,
        allowNull: true,
    },
}, {
    tableName: "tb_purchased_receipt",
    timestamps: false,
});

export default PurchasedReceipt;