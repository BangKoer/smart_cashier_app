import { Sequelize, DataTypes } from "sequelize";
import sequelize from "../database.js";
import Product from "./Product.js";
import ProductUnit from "./ProductUnit.js";

const SaleItem = sequelize.define(
  "SaleItem",
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    id_sales: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    id_product: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    id_product_unit: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    quantity: {
      type: DataTypes.FLOAT,
      allowNull: false,
    },
    sub_total: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
    },
  },
  {
    tableName: "tb_sale_item",
    timestamps: false,
  }
);

// // RELASI
// SaleItem.belongsTo(Product, { foreignKey: "id_product", as: "product" });
// SaleItem.belongsTo(ProductUnit, { foreignKey: "id_product_unit", as: "unit" });

export default SaleItem;
