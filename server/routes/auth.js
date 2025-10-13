import express from "express"
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import User from "../models/User.js";
import authMiddleware from "../middlewares/auth.js"

const authRouter = express.Router();
const JWT_SECRET = "rahasia";


// POST Register API
authRouter.post('/admin/register', async (req, res) => {
    try {
        const { name, email, password, role } = req.body;
        const userExists = await User.findOne({ where: { email } })
        if (userExists) {
            return res.status(400).json({
                msg: `User with ${email} already Exists`
            })
        }
        const hashedPassword = await bcrypt.hash(password, 10);
        let user = await User.create({
            name,
            email,
            password: hashedPassword,
            role,
        })
        res.status(201).json({
            msg: "User Registered",
            user
        })
    } catch (e) {
        res.status(500).json({
            error: e.message
        })
    }
})

// POST Login API
authRouter.post('/admin/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        const user = await User.findOne({ where: { email } });
        if (!user) return res.status(400).json({ msg: "User With This Email Doesn\'t Exist" })

        const isPasswordValid = await bcrypt.compare(password, user.password)
        if (!isPasswordValid) return res.status(400).json({ msg: "Incorrect Password, Try Again!" })

        const token = jwt.sign({ id: user.id, role: user.role }, JWT_SECRET)
        res.json({ token, ...user.toJSON() })
    } catch (e) {
        res.status(500).json({
            error: e.message
        })
    }
})

authRouter.post('/IsTokenValid', async (req, res) => {
    try {
        const token = req.header("x-auth-token");
        if (!token) return res.json(false);

        const tokenVerified = jwt.verify(token, JWT_SECRET);
        if (!tokenVerified) return res.json(false);

        const user = await User.findOne({ where: { id: tokenVerified.id } })
        if (!user) return res.json(false);

        res.json(true)
    } catch (e) {
        res.status(500).json({
            error: e.message,
        })
    }
})

authRouter.get('/', authMiddleware, async (req, res) => {
    try {
        const user = await User.findByPk(req.user)
        if (!user) return res.status(404).json({ msg: "User not Found" });
        res.json({ ...user.dataValues, token: req.token });
    } catch (e) {
        res.status(500).json({ error: e.message })
    }

})

export default authRouter;