import { db } from '../database/index.js';
import { NotFoundError, ValidationError } from '../errors/index.js';
import { safeFormat } from '../utils/helpers.js';

class PremisesFormService {
  async submitPremisesForm(userData, body) {
    return { message: 'Premises form endpoint placeholder' };
  }

  async getPremisesForms(filters) {
    return { count: 0, forms: [] };
  }

  async getPremisesFormById(uid) {
    if (!uid) throw new ValidationError("Form ID is required.");
    const doc = await db.collection('premisesForms').doc(uid).get();
    if (!doc.exists) throw new NotFoundError("Form not found.");
    return doc.data();
  }
}

export const premisesFormService = new PremisesFormService();
