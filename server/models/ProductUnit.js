import { DataTypes } from "sequelize";
import sequelize from "../database.js";

const ProductUnit = sequelize.define(
    "ProductUnit",
    {
        id: { type : DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
        id_product : DataTypes.INTEGER,
        name_unit : DataTypes.STRING,
        price : DataTypes.FLOAT,
        conversion : DataTypes.INTEGER, 
    },
    {
        tableName: "tb_product_unit",
        timestamps: false,
    }
)

export default ProductUnit;