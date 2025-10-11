'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tb_product', {
      id: {
        type: Sequelize.INTEGER,
        autoIncrement: true,
        primaryKey: true,
      },
      barcode: Sequelize.STRING,
      product_name: Sequelize.STRING,
      id_category: Sequelize.INTEGER,
      stock: Sequelize.INTEGER,
      purchased_price: Sequelize.FLOAT,
      created_at: { 
        type: Sequelize.DATE, 
        defaultValue: Sequelize.NOW,
      },
      updated_at: { 
        type: Sequelize.DATE, 
        defaultValue: Sequelize.NOW,
      },
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tb_product')
  }
};
