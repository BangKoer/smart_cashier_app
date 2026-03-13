// relations.js
import Category from "./category.js";
import Product from "./Product.js";
import ProductUnit from "./ProductUnit.js";
// import StockAudit from "./StockAudit.js";
import User from "./User.js";
import Sales from "./sales.js";
import SaleItem from "./SaleItem.js";
import PurchasedReceipt from "./PurchasedReceipt.js";
import PurchasedReceiptItem from "./PurchasedReceiptItem.js";
import PurchasedReceiptFile from "./PurchasedReceiptFile.js";
import Supplier from "./supplier.js";

// Category - Product
Category.hasMany(Product, { foreignKey: "id_category", as: "products" });
Product.belongsTo(Category, { foreignKey: "id_category", as: "category" });

// Product - ProductUnit
Product.hasMany(ProductUnit, { foreignKey: "id_product", as: "units" });
ProductUnit.belongsTo(Product, { foreignKey: "id_product", as: "product" });

// Product - StockAudit
// Product.hasMany(StockAudit, { foreignKey: "id_product", as: "stock_audits" });
// StockAudit.belongsTo(Product, { foreignKey: "id_product", as: "product" });

// User - Sales
User.hasMany(Sales, { foreignKey: "id_user", as: "sales" });
Sales.belongsTo(User, { foreignKey: "id_user", as: "user" });

// Sales - SaleItem
Sales.hasMany(SaleItem, { foreignKey: "id_sales", as: "items" });
SaleItem.belongsTo(Sales, { foreignKey: "id_sales", as: "sales" });

// SaleItem - Product
SaleItem.belongsTo(Product, { foreignKey: "id_product", as: "product" });

// SaleItem - ProductUnit
SaleItem.belongsTo(ProductUnit, { foreignKey: "id_product_unit", as: "unit" });

// PurchasedReceipt - Supplier
PurchasedReceipt.belongsTo(Supplier, { foreignKey: "id_supplier" });
Supplier.hasMany(PurchasedReceipt, { foreignKey: "id_supplier", as: "receipts" });

// PurchasedReceipt - Items
PurchasedReceipt.hasMany(PurchasedReceiptItem, {
  foreignKey: "id_purchase_receipt",
  as: "items",
});
PurchasedReceiptItem.belongsTo(PurchasedReceipt, {
  foreignKey: "id_purchase_receipt",
  as: "receipt",
});

// PurchasedReceipt - Files
PurchasedReceipt.hasMany(PurchasedReceiptFile, {
  foreignKey: "id_purchase_receipt",
  as: "files",
});
PurchasedReceiptFile.belongsTo(PurchasedReceipt, {
  foreignKey: "id_purchase_receipt",
  as: "receipt",
});

// PurchasedReceiptItem - Product
PurchasedReceiptItem.belongsTo(Product, { foreignKey: "id_product", as: "product" });



export {
  Category,
  Product,
  ProductUnit,
  // StockAudit,
  User,
  Sales,
  SaleItem,
  PurchasedReceipt,
  PurchasedReceiptItem,
  PurchasedReceiptFile,
};
