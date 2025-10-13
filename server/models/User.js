import { Sequelize, DataTypes } from "sequelize";
import sequelize from "../database.js";

const User = sequelize.define(
    'User',
    {
        id : {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement:true,
        },
        name :{ 
            type: DataTypes.STRING,
            allowNull:false,
        },
        email: {
            type: DataTypes.STRING,
            allowNull:false,
            unique:true,
            validate:{
                isEmail:{
                    msg: 'Please Enter Valid Email'
                }
            }
        },
        password: {
            type: DataTypes.STRING,
            allowNull:false,
            validate:{
                len: {
                    args: [7,255],
                    msg: "Password must be at least 8 character long"
                },
                isStrong(value){
                    const regexPass = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).+$/;
                    if (!regexPass.test(value)) {
                        throw new Error("PasswordPassword must include uppercase, lowercase, number, and special character");
                    }
                }
            }
        },
        role : {
            type: DataTypes.ENUM("cashier","admin"),
            defaultValue:"cashier",
            allowNull:false,
        },
        created_at:{
            type: DataTypes.DATE,
            defaultValue: Sequelize.NOW,
        }
    },
    {
        tableName: "tb_user",
        timestamps:false,
    }
);

export default User;


