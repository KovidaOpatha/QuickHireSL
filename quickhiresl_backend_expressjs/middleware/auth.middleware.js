// const jwt = require('jsonwebtoken');

// const authMiddleware = (req, res, next) => {
//     try {
//         const token = req.headers.authorization.split(' ')[1];
//         const decoded = jwt.verify(token, process.env.JWT_SECRET);
//         req.userData = decoded;
//         next();
//     } catch (error) {
//         return res.status(401).json({
//             message: 'Authentication failed'
//         });
//     }
// };

// module.exports = authMiddleware;













// const jwt = require('jsonwebtoken');

// const authMiddleware = (req, res, next) => {
//     try {
//         // Expecting the token format: "Bearer <token>"
//         const token = req.headers.authorization && req.headers.authorization.split(' ')[1];
//         if (!token) {
//             return res.status(401).json({ message: 'Authentication token missing' });
//         }
//         const decoded = jwt.verify(token, process.env.JWT_SECRET);
//         req.userData = decoded;
//         next();
//     } catch (error) {
//         console.error('Auth Middleware error:', error);
//         return res.status(401).json({ message: 'Authentication failed' });
//     }
// };

// module.exports = authMiddleware;



const jwt = require('jsonwebtoken');

class AuthMiddleware {
    static authenticate(req, res, next) {
        try {
            const token = req.headers.authorization?.split(' ')[1];

            if (!token) {
                return res.status(401).json({ message: 'Authentication token missing' });
            }

            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            req.userData = decoded;
            next();
        } catch (error) {
            console.error('Auth Middleware error:', error);
            return res.status(401).json({ message: 'Authentication failed' });
        }
    }
}

module.exports = AuthMiddleware;


// const jwt = require('jsonwebtoken');

// class AuthMiddleware {
//     static authenticate(req, res, next) {
//         try {
//             const token = req.headers.authorization?.split(' ')[1];

//             if (!token) {
//                 return res.status(401).json({ message: 'Authentication token missing' });
//             }

//             const decoded = jwt.verify(token, process.env.JWT_SECRET);
//             req.userData = decoded;
//             next();
//         } catch (error) {
//             console.error('Auth Middleware error:', error);
//             return res.status(401).json({ message: 'Authentication failed' });
//         }
//     }
// }

// module.exports = AuthMiddleware;
