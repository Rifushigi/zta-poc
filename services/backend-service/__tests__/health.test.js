const request = require('supertest');
const express = require('express');
const app = require('../app');

describe('Health Endpoint', () => {
    it('should return healthy status', async () => {
        const res = await request(app).get('/health');
        expect(res.statusCode).toBe(200);
        expect(res.body.status).toBe('healthy');
    });
}); 