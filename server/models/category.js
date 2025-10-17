import { Sequelize, DataTypes } from "sequelize";
import sequelize from "../database.js";

const Category = sequelize.define(
    "Category", {
        id : {
            type: DataTypes.STRING,
            primaryKey: true,
            autoIncrement: true,
        },
        name: DataTypes.STRING,
    },
    {
        tableName: "tb_categories",
        timestamps:false,
    },
);

export default Category;