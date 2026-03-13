import { DataTypes } from "sequelize";
import sequelize from "../database.js";

const PurchasedReceiptFile = sequelize.define("PurchasedReceiptFile", {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  id_purchase_receipt: { type: DataTypes.INTEGER, allowNull: false },
  file_path: { type: DataTypes.STRING(255), allowNull: false },
  original_name: { type: DataTypes.STRING(255), allowNull: false },
  mime_type: { type: DataTypes.STRING(100), allowNull: false },
  file_size: { type: DataTypes.INTEGER, allowNull: false },
}, {
  tableName: "tb_purchased_receipt_file",
  timestamps: false,
});

export default PurchasedReceiptFile;