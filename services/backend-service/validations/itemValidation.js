const Joi = require('joi');

const createItemSchema = Joi.object({
    name: Joi.string().min(1).max(255).required()
        .messages({
            'string.empty': 'Name cannot be empty',
            'string.min': 'Name must be at least 1 character long',
            'string.max': 'Name cannot exceed 255 characters',
            'any.required': 'Name is required'
        }),
    description: Joi.string().min(1).max(1000).required()
        .messages({
            'string.empty': 'Description cannot be empty',
            'string.min': 'Description must be at least 1 character long',
            'string.max': 'Description cannot exceed 1000 characters',
            'any.required': 'Description is required'
        })
});

const updateItemSchema = Joi.object({
    name: Joi.string().min(1).max(255).optional()
        .messages({
            'string.empty': 'Name cannot be empty',
            'string.min': 'Name must be at least 1 character long',
            'string.max': 'Name cannot exceed 255 characters'
        }),
    description: Joi.string().min(1).max(1000).optional()
        .messages({
            'string.empty': 'Description cannot be empty',
            'string.min': 'Description must be at least 1 character long',
            'string.max': 'Description cannot exceed 1000 characters'
        })
});

const paginationSchema = Joi.object({
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(10)
});

module.exports = {
    createItemSchema,
    updateItemSchema,
    paginationSchema
}; 