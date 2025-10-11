import { Sequelize } from "sequelize";

const sequelize = new Sequelize('db_cashier', 'root', null, {
    host: "0.0.0.0",
    dialect: 'mysql',
})

export default sequelize;