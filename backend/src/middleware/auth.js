import jwt from 'jsonwebtoken';
import { db } from '../database/index.js';

export const verifyToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).send({ error: 'No token provided.' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userDoc = await db.collection('users').doc(decoded.uid).get();

    if (!userDoc.exists) {
      return res.status(401).send({ error: 'User no longer exists.' });
    }

    const userData = userDoc.data();

    let entityDetails = null;
    if (userData.entityId) {
      const entityDoc = await db.collection('entities').doc(userData.entityId).get();
      if (entityDoc.exists) {
        entityDetails = entityDoc.data();
      }
    }

    req.user = {
      uid: decoded.uid,
      email: decoded.email,
      role: decoded.role,
      fullName: userData.fullName,
      name: userData.fullName,
      zone: userData.zone,
      division: userData.division,
      depot: userData.depot,
      userType: userData.userType,
      entityId: userData.entityId,
      entityName: entityDetails?.companyName || null,
      entityDetails: entityDetails
    };

    next();
  } catch (err) {
    console.error('Middleware Error:', err);
    return res.status(403).send({ error: 'Invalid or expired token.' });
  }
};
