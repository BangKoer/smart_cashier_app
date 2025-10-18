import { Sequelize, DataTypes } from "sequelize";
import sequelize from "../database.js";
import SaleItem from "./SaleItem.js";
import User from "./User.js";

const Sales = sequelize.define(
    "Sales", 
    {
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey:true,
        },
        id_user: {
            type: DataTypes.INTEGER,
            allowNull:false,
            references: {
                model: "tb_user",
                key: "id",
            },
        },
        total_price: DataTypes.DECIMAL,
        payment_method: DataTypes.STRING,
        payment_status: {
            type: DataTypes.ENUM("paid", "pending"),
            defaultValue: "paid",
            allowNull:false,
        },
        customer_name: {
            type: DataTypes.STRING,
            allowNull: true,
        },
        created_at: {
            type: DataTypes.DATE,
            defaultValue: Sequelize.NOW,
        }
    },
    {
        tableName: "tb_sales",
        timestamps: false,
    }
);

export default Sales;