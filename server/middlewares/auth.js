import jwt from 'jsonwebtoken'



const auth = async (req, res, next) => {
    const JWT_SECRET = "rahasia";
    try {
        const token = req.header('x-auth-token')
        if(!token) return res.status(401).json({ msg : "No Auth Token, Access Denied" });

        const verified = jwt.verify(token, JWT_SECRET)
        if(!verified) return res.status(401).json({ msg: "Token Verification failed, Authorization Denied" })

        req.user = verified.id,
        req.token = token;
        next()
    } catch (e) {
        res.status(500).json({ error : e.message });
    }
}

export default auth;


