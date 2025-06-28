const validationMiddleware = (schema) => {
    return (req, res, next) => {
        const { error, value } = schema.validate(req.body);

        if (error) {
            return res.status(400).json({
                error: 'Validation failed',
                details: error.details.map(detail => ({
                    field: detail.path.join('.'),
                    message: detail.message
                }))
            });
        }

        // Replace req.body with validated data
        req.body = value;
        next();
    };
};

const queryValidationMiddleware = (schema) => {
    return (req, res, next) => {
        const { error, value } = schema.validate(req.query);

        if (error) {
            return res.status(400).json({
                error: 'Query validation failed',
                details: error.details.map(detail => ({
                    field: detail.path.join('.'),
                    message: detail.message
                }))
            });
        }

        // Replace req.query with validated data
        req.query = value;
        next();
    };
};

module.exports = {
    validationMiddleware,
    queryValidationMiddleware
}; 