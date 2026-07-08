import { ValidationError } from '../errors/AppError.js';

export function validate(schema, source = 'body') {
  return (req, res, next) => {
    const result = schema.safeParse(req[source]);
    if (!result.success) {
      const issues = result.error.issues || result.error.errors || [];
      const details = issues.map(e => ({
        field: e.path.join('.'),
        message: e.message,
        code: e.code
      }));
      return next(new ValidationError('Validation failed', JSON.stringify(details)));
    }
    req[source] = result.data;
    next();
  };
}
