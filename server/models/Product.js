import { Sequelize, DataTypes } from "sequelize";
import sequelize from "../database.js";
import ProductUnit from "./ProductUnit.js"

const Product = sequelize.define(
    "Product",
    {
        id: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true,
        },
        barcode: DataTypes.STRING,
        product_name: DataTypes.STRING,
        id_category: DataTypes.INTEGER,
        stock: DataTypes.INTEGER,
        purchased_price: DataTypes.FLOAT,
        created_at: {
            type: DataTypes.DATE,
            defaultValue: Sequelize.NOW,
        },
        updated_at: {
            type: DataTypes.DATE,
            defaultValue: Sequelize.NOW,
        },
    },
    {
        tableName: "tb_product",
        timestamps: false,
    }
);

Product.hasMany(ProductUnit, { foreignKey : "id_product"})
ProductUnit.belongsTo(Product, {foreignKey : "id_product"})

export default Product;