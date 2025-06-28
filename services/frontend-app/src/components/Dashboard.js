import React from 'react';
import {
    Grid,
    Card,
    CardContent,
    Typography,
    Box,
    Avatar,
    Chip,
    List,
    ListItem,
    ListItemText,
    ListItemIcon,
    Divider,
    Alert,
    LinearProgress
} from '@mui/material';
import {
    Person,
    Security,
    CheckCircle,
    Warning,
    Error,
    Schedule,
    VerifiedUser,
    AdminPanelSettings
} from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';

const Dashboard = () => {
    const { user } = useAuth();

    const systemStatus = [
        { service: 'Keycloak', status: 'healthy', icon: <CheckCircle color="success" /> },
        { service: 'API Gateway', status: 'healthy', icon: <CheckCircle color="success" /> },
        { service: 'Backend Service', status: 'healthy', icon: <CheckCircle color="success" /> },
        { service: 'OPA Policy Engine', status: 'healthy', icon: <CheckCircle color="success" /> },
        { service: 'Database', status: 'healthy', icon: <CheckCircle color="success" /> }
    ];

    const recentActivity = [
        { action: 'Login successful', time: '2 minutes ago', type: 'success' },
        { action: 'Data accessed', time: '5 minutes ago', type: 'info' },
        { action: 'Policy evaluation', time: '10 minutes ago', type: 'info' },
        { action: 'Token refreshed', time: '15 minutes ago', type: 'info' }
    ];

    const getStatusColor = (status) => {
        switch (status) {
            case 'healthy': return 'success';
            case 'warning': return 'warning';
            case 'error': return 'error';
            default: return 'default';
        }
    };

    return (
        <Box>
            <Typography variant="h4" gutterBottom>
                Welcome back, {user?.name || user?.username}!
            </Typography>

            <Grid container spacing={3}>
                {/* User Profile Card */}
                <Grid item xs={12} md={4}>
                    <Card>
                        <CardContent>
                            <Box display="flex" alignItems="center" mb={2}>
                                <Avatar
                                    sx={{ width: 64, height: 64, mr: 2, bgcolor: 'primary.main' }}
                                >
                                    <Person />
                                </Avatar>
                                <Box>
                                    <Typography variant="h6">{user?.name || user?.username}</Typography>
                                    <Typography variant="body2" color="text.secondary">
                                        {user?.email}
                                    </Typography>
                                </Box>
                            </Box>

                            <Divider sx={{ my: 2 }} />

                            <Typography variant="subtitle2" gutterBottom>
                                Roles & Permissions
                            </Typography>
                            <Box display="flex" flexWrap="wrap" gap={1}>
                                {user?.roles?.map(role => (
                                    <Chip
                                        key={role}
                                        label={role}
                                        size="small"
                                        color="primary"
                                        variant="outlined"
                                    />
                                ))}
                            </Box>
                        </CardContent>
                    </Card>
                </Grid>

                {/* System Status */}
                <Grid item xs={12} md={8}>
                    <Card>
                        <CardContent>
                            <Typography variant="h6" gutterBottom>
                                System Status
                            </Typography>
                            <List>
                                {systemStatus.map((service, index) => (
                                    <ListItem key={service.service}>
                                        <ListItemIcon>
                                            {service.icon}
                                        </ListItemIcon>
                                        <ListItemText
                                            primary={service.service}
                                            secondary={`Status: ${service.status}`}
                                        />
                                        <Chip
                                            label={service.status}
                                            size="small"
                                            color={getStatusColor(service.status)}
                                            variant="outlined"
                                        />
                                    </ListItem>
                                ))}
                            </List>
                        </CardContent>
                    </Card>
                </Grid>

                {/* Security Overview */}
                <Grid item xs={12} md={6}>
                    <Card>
                        <CardContent>
                            <Typography variant="h6" gutterBottom>
                                Security Overview
                            </Typography>

                            <Box mb={3}>
                                <Box display="flex" justifyContent="space-between" mb={1}>
                                    <Typography variant="body2">Authentication Status</Typography>
                                    <Chip label="Secure" size="small" color="success" />
                                </Box>
                                <LinearProgress variant="determinate" value={100} color="success" />
                            </Box>

                            <Box mb={3}>
                                <Box display="flex" justifyContent="space-between" mb={1}>
                                    <Typography variant="body2">Authorization Status</Typography>
                                    <Chip label="Active" size="small" color="success" />
                                </Box>
                                <LinearProgress variant="determinate" value={100} color="success" />
                            </Box>

                            <Box mb={3}>
                                <Box display="flex" justifyContent="space-between" mb={1}>
                                    <Typography variant="body2">Policy Enforcement</Typography>
                                    <Chip label="Enforced" size="small" color="success" />
                                </Box>
                                <LinearProgress variant="determinate" value={100} color="success" />
                            </Box>

                            <Alert severity="info" sx={{ mt: 2 }}>
                                All security controls are active and functioning properly.
                            </Alert>
                        </CardContent>
                    </Card>
                </Grid>

                {/* Recent Activity */}
                <Grid item xs={12} md={6}>
                    <Card>
                        <CardContent>
                            <Typography variant="h6" gutterBottom>
                                Recent Activity
                            </Typography>
                            <List>
                                {recentActivity.map((activity, index) => (
                                    <ListItem key={index}>
                                        <ListItemIcon>
                                            {activity.type === 'success' ? (
                                                <CheckCircle color="success" />
                                            ) : (
                                                <Schedule color="info" />
                                            )}
                                        </ListItemIcon>
                                        <ListItemText
                                            primary={activity.action}
                                            secondary={activity.time}
                                        />
                                    </ListItem>
                                ))}
                            </List>
                        </CardContent>
                    </Card>
                </Grid>

                {/* Zero Trust Principles */}
                <Grid item xs={12}>
                    <Card>
                        <CardContent>
                            <Typography variant="h6" gutterBottom>
                                Zero Trust Principles in Action
                            </Typography>
                            <Grid container spacing={2}>
                                <Grid item xs={12} sm={6} md={3}>
                                    <Box textAlign="center" p={2}>
                                        <VerifiedUser sx={{ fontSize: 40, color: 'primary.main', mb: 1 }} />
                                        <Typography variant="subtitle1">Identity Verification</Typography>
                                        <Typography variant="body2" color="text.secondary">
                                            Multi-factor authentication with Keycloak
                                        </Typography>
                                    </Box>
                                </Grid>
                                <Grid item xs={12} sm={6} md={3}>
                                    <Box textAlign="center" p={2}>
                                        <Security sx={{ fontSize: 40, color: 'primary.main', mb: 1 }} />
                                        <Typography variant="subtitle1">Policy Enforcement</Typography>
                                        <Typography variant="body2" color="text.secondary">
                                            OPA policies control access to resources
                                        </Typography>
                                    </Box>
                                </Grid>
                                <Grid item xs={12} sm={6} md={3}>
                                    <Box textAlign="center" p={2}>
                                        <AdminPanelSettings sx={{ fontSize: 40, color: 'primary.main', mb: 1 }} />
                                        <Typography variant="subtitle1">Least Privilege</Typography>
                                        <Typography variant="body2" color="text.secondary">
                                            Role-based access control (RBAC)
                                        </Typography>
                                    </Box>
                                </Grid>
                                <Grid item xs={12} sm={6} md={3}>
                                    <Box textAlign="center" p={2}>
                                        <CheckCircle sx={{ fontSize: 40, color: 'primary.main', mb: 1 }} />
                                        <Typography variant="subtitle1">Continuous Monitoring</Typography>
                                        <Typography variant="body2" color="text.secondary">
                                            Real-time security monitoring and alerts
                                        </Typography>
                                    </Box>
                                </Grid>
                            </Grid>
                        </CardContent>
                    </Card>
                </Grid>
            </Grid>
        </Box>
    );
};

export default Dashboard; 