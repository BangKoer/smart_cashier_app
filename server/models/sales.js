import { Sequelize, DataTypes } from "sequelize";
import sequelize from "../database.js";

const Sales = sequelize.define(
    "Sales",
    {
        id: {
            type: DataTypes.INTEGER,
            autoIncrement: true,
            primaryKey: true,
        },
        id_user: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: "tb_user",
                key: "id",
            },
        },
        total_price: {
            type: DataTypes.DECIMAL(10, 2),
            allowNull: false,
        },
        total_payout: {
            type: DataTypes.DECIMAL(10, 2),
            allowNull: false,
            defaultValue: 0,
        },
        payment_method: {
            type: DataTypes.STRING,
            allowNull: false,
        },
        payment_status: {
            type: DataTypes.ENUM("paid", "pending"),
            defaultValue: "paid",
            allowNull: false,
        },
        customer_name: {
            type: DataTypes.STRING,
            allowNull: true,
        },
        created_at: {
            type: DataTypes.DATE,
            defaultValue: Sequelize.NOW,
            allowNull: false,
        }
    },
    {
        tableName: "tb_sales",
        timestamps: false,
    }
);

export default Sales;
