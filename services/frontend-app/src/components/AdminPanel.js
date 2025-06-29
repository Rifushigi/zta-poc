import React, { useState } from 'react';
import {
    Box,
    Card,
    CardContent,
    Typography,
    Grid,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    Paper,
    Chip,
    Alert,
    CircularProgress,
    Tabs,
    Tab,
    List,
    ListItem,
    ListItemText,
    ListItemIcon,
    Divider
} from '@mui/material';
import {
    AdminPanelSettings,
    People,
    Security,
    Assessment,
    CheckCircle,
    Warning,
    Error,
    Schedule
} from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';
import { useQuery } from '@tanstack/react-query';
import axios from 'axios';

const AdminPanel = () => {
    const { getToken } = useAuth();
    const [activeTab, setActiveTab] = useState(0);

    // API configuration
    const api = axios.create({
        baseURL: process.env.REACT_APP_API_URL || 'http://localhost:3000'
    });

    // Add auth interceptor
    api.interceptors.request.use(async (config) => {
        const token = await getToken();
        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
    });

    // Fetch admin data
    const { data: adminData, isLoading: adminLoading, error: adminError } = useQuery(
        ['admin-data'],
        async () => {
            const response = await api.get('/api/admin');
            return response.data;
        },
        {
            retry: 1,
            onError: (error) => {
                console.error('Failed to fetch admin data:', error);
            }
        }
    );

    // Mock system metrics
    const systemMetrics = {
        totalUsers: 15,
        activeUsers: 8,
        totalItems: 127,
        systemUptime: '99.9%',
        avgResponseTime: '245ms',
        errorRate: '0.1%'
    };

    // Mock security events
    const securityEvents = [
        { id: 1, event: 'Failed login attempt', user: 'unknown', ip: '192.168.1.100', time: '2 minutes ago', severity: 'warning' },
        { id: 2, event: 'Policy violation', user: 'user1', ip: '192.168.1.101', time: '5 minutes ago', severity: 'error' },
        { id: 3, event: 'Successful login', user: 'admin', ip: '192.168.1.102', time: '10 minutes ago', severity: 'info' },
        { id: 4, event: 'Data access', user: 'user2', ip: '192.168.1.103', time: '15 minutes ago', severity: 'info' }
    ];

    const getSeverityColor = (severity) => {
        switch (severity) {
            case 'error': return 'error';
            case 'warning': return 'warning';
            case 'info': return 'info';
            default: return 'default';
        }
    };

    const getSeverityIcon = (severity) => {
        switch (severity) {
            case 'error': return <Error color="error" />;
            case 'warning': return <Warning color="warning" />;
            case 'info': return <CheckCircle color="info" />;
            default: return <Schedule />;
        }
    };

    const TabPanel = ({ children, value, index }) => (
        <div hidden={value !== index} style={{ paddingTop: 20 }}>
            {value === index && children}
        </div>
    );

    return (
        <Box>
            <Box display="flex" alignItems="center" mb={3}>
                <AdminPanelSettings sx={{ fontSize: 40, color: 'primary.main', mr: 2 }} />
                <Typography variant="h4">
                    Admin Panel
                </Typography>
            </Box>

            <Alert severity="warning" sx={{ mb: 3 }}>
                This panel is restricted to administrators only. All actions are logged and audited.
            </Alert>

            <Grid container spacing={3}>
                {/* System Overview */}
                <Grid item xs={12} md={8}>
                    <Card>
                        <CardContent>
                            <Typography variant="h6" gutterBottom>
                                System Overview
                            </Typography>
                            <Grid container spacing={2}>
                                <Grid item xs={6} sm={3}>
                                    <Box textAlign="center" p={2}>
                                        <Typography variant="h4" color="primary">
                                            {systemMetrics.totalUsers}
                                        </Typography>
                                        <Typography variant="body2" color="text.secondary">
                                            Total Users
                                        </Typography>
                                    </Box>
                                </Grid>
                                <Grid item xs={6} sm={3}>
                                    <Box textAlign="center" p={2}>
                                        <Typography variant="h4" color="success.main">
                                            {systemMetrics.activeUsers}
                                        </Typography>
                                        <Typography variant="body2" color="text.secondary">
                                            Active Users
                                        </Typography>
                                    </Box>
                                </Grid>
                                <Grid item xs={6} sm={3}>
                                    <Box textAlign="center" p={2}>
                                        <Typography variant="h4" color="info.main">
                                            {systemMetrics.totalItems}
                                        </Typography>
                                        <Typography variant="body2" color="text.secondary">
                                            Total Items
                                        </Typography>
                                    </Box>
                                </Grid>
                                <Grid item xs={6} sm={3}>
                                    <Box textAlign="center" p={2}>
                                        <Typography variant="h4" color="success.main">
                                            {systemMetrics.systemUptime}
                                        </Typography>
                                        <Typography variant="body2" color="text.secondary">
                                            Uptime
                                        </Typography>
                                    </Box>
                                </Grid>
                            </Grid>
                        </CardContent>
                    </Card>
                </Grid>

                {/* Performance Metrics */}
                <Grid item xs={12} md={4}>
                    <Card>
                        <CardContent>
                            <Typography variant="h6" gutterBottom>
                                Performance
                            </Typography>
                            <List>
                                <ListItem>
                                    <ListItemText
                                        primary="Average Response Time"
                                        secondary={systemMetrics.avgResponseTime}
                                    />
                                </ListItem>
                                <ListItem>
                                    <ListItemText
                                        primary="Error Rate"
                                        secondary={systemMetrics.errorRate}
                                    />
                                </ListItem>
                            </List>
                        </CardContent>
                    </Card>
                </Grid>

                {/* Admin Tabs */}
                <Grid item xs={12}>
                    <Card>
                        <CardContent>
                            <Tabs value={activeTab} onChange={(e, newValue) => setActiveTab(newValue)}>
                                <Tab label="All Data" icon={<Assessment />} />
                                <Tab label="Security Events" icon={<Security />} />
                                <Tab label="User Management" icon={<People />} />
                            </Tabs>

                            <TabPanel value={activeTab} index={0}>
                                {adminLoading ? (
                                    <Box display="flex" justifyContent="center" p={3}>
                                        <CircularProgress />
                                    </Box>
                                ) : adminError ? (
                                    <Alert severity="error">
                                        Failed to load admin data. You may not have admin privileges.
                                    </Alert>
                                ) : (
                                    <TableContainer component={Paper} variant="outlined">
                                        <Table>
                                            <TableHead>
                                                <TableRow>
                                                    <TableCell>Name</TableCell>
                                                    <TableCell>Description</TableCell>
                                                    <TableCell>Owner</TableCell>
                                                    <TableCell>Created</TableCell>
                                                    <TableCell>Status</TableCell>
                                                </TableRow>
                                            </TableHead>
                                            <TableBody>
                                                {adminData?.items?.map((item) => (
                                                    <TableRow key={item.id}>
                                                        <TableCell>{item.name}</TableCell>
                                                        <TableCell>{item.description}</TableCell>
                                                        <TableCell>
                                                            <Chip
                                                                label={item.owner}
                                                                size="small"
                                                                color="primary"
                                                                variant="outlined"
                                                            />
                                                        </TableCell>
                                                        <TableCell>
                                                            {new Date(item.createdAt).toLocaleDateString()}
                                                        </TableCell>
                                                        <TableCell>
                                                            <Chip
                                                                label="Active"
                                                                size="small"
                                                                color="success"
                                                            />
                                                        </TableCell>
                                                    </TableRow>
                                                ))}
                                            </TableBody>
                                        </Table>
                                    </TableContainer>
                                )}
                            </TabPanel>

                            <TabPanel value={activeTab} index={1}>
                                <List>
                                    {securityEvents.map((event) => (
                                        <ListItem key={event.id}>
                                            <ListItemIcon>
                                                {getSeverityIcon(event.severity)}
                                            </ListItemIcon>
                                            <ListItemText
                                                primary={event.event}
                                                secondary={`${event.user} (${event.ip}) - ${event.time}`}
                                            />
                                            <Chip
                                                label={event.severity}
                                                size="small"
                                                color={getSeverityColor(event.severity)}
                                            />
                                        </ListItem>
                                    ))}
                                </List>
                            </TabPanel>

                            <TabPanel value={activeTab} index={2}>
                                <Typography variant="body1" color="text.secondary" sx={{ mb: 2 }}>
                                    User management functionality would be implemented here.
                                </Typography>
                                <Alert severity="info">
                                    This would include user creation, role assignment, and access management.
                                </Alert>
                            </TabPanel>
                        </CardContent>
                    </Card>
                </Grid>
            </Grid>
        </Box>
    );
};

export default AdminPanel; 