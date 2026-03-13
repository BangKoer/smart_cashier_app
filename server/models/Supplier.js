import { DataTypes } from "sequelize";
import sequelize from "../database.js";

const Supplier = sequelize.define(
    "Supplier", {
    id: {
        type: DataTypes.INTEGER,
        autoIncrement: true,
        primaryKey: true
    },
    supplier_name: {
        type: DataTypes.STRING(255),
        allowNull: false,
    },
    company: {
        type: DataTypes.STRING(100),
        allowNull: true,
    },
    phone: {
        type: DataTypes.STRING(30),
        allowNull: true,
    },
    address: {
        type: DataTypes.TEXT,
        allowNull: false,
    }
}, {
    tableName: "tb_supplier",
    timestamps: false,
});

export default Supplier;