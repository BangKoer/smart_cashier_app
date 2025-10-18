// relations.js
import Category from "./category.js";
import Product from "./Product.js";
import ProductUnit from "./ProductUnit.js";
// import StockAudit from "./StockAudit.js";
import User from "./User.js";
import Sales from "./sales.js";
import SaleItem from "./SaleItem.js";

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

export {
  Category,
  Product,
  ProductUnit,
  // StockAudit,
  User,
  Sales,
  SaleItem,
};
