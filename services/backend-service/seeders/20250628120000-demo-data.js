'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
    async up(queryInterface, Sequelize) {
        const demoItems = [
            {
                name: 'Project Alpha',
                description: 'A comprehensive zero trust implementation project',
                owner: 'admin',
                createdAt: new Date(),
                updatedAt: new Date()
            },
            {
                name: 'Security Audit Report',
                description: 'Quarterly security assessment and recommendations',
                owner: 'admin',
                createdAt: new Date(),
                updatedAt: new Date()
            },
            {
                name: 'User Training Materials',
                description: 'Documentation and guides for zero trust principles',
                owner: 'user',
                createdAt: new Date(),
                updatedAt: new Date()
            },
            {
                name: 'Network Configuration',
                description: 'Current network topology and security zones',
                owner: 'user',
                createdAt: new Date(),
                updatedAt: new Date()
            },
            {
                name: 'Incident Response Plan',
                description: 'Procedures for handling security incidents',
                owner: 'admin',
                createdAt: new Date(),
                updatedAt: new Date()
            },
            {
                name: 'Compliance Checklist',
                description: 'Regulatory compliance requirements and status',
                owner: 'user',
                createdAt: new Date(),
                updatedAt: new Date()
            }
        ];

        await queryInterface.bulkInsert('Items', demoItems, {});
    },

    async down(queryInterface, Sequelize) {
        await queryInterface.bulkDelete('Items', null, {});
    }
}; 