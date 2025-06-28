import React from 'react';
import {
    Box,
    Card,
    CardContent,
    Typography,
    Grid,
    List,
    ListItem,
    ListItemText,
    ListItemIcon,
    Chip,
    Alert,
    LinearProgress,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    Paper
} from '@mui/material';
import {
    Security,
    CheckCircle,
    Warning,
    Error,
    TrendingUp,
    TrendingDown,
    Shield,
    Lock,
    Visibility,
    Block
} from '@mui/icons-material';

const SecurityOverview = () => {
    // Mock security metrics
    const securityMetrics = {
        authSuccessRate: 98.5,
        authFailures: 12,
        policyDecisions: 1247,
        allowedRequests: 1189,
        deniedRequests: 58,
        suspiciousActivity: 3,
        activeThreats: 0,
        certificateExpiry: 45 // days
    };

    // Mock recent security events
    const securityEvents = [
        {
            id: 1,
            event: 'Authentication Success',
            user: 'user1',
            ip: '192.168.1.100',
            time: '2 minutes ago',
            severity: 'success'
        },
        {
            id: 2,
            event: 'Policy Violation - Unauthorized Access',
            user: 'user2',
            ip: '192.168.1.101',
            time: '5 minutes ago',
            severity: 'error'
        },
        {
            id: 3,
            event: 'Rate Limit Exceeded',
            user: 'unknown',
            ip: '192.168.1.102',
            time: '10 minutes ago',
            severity: 'warning'
        },
        {
            id: 4,
            event: 'JWT Token Expired',
            user: 'user3',
            ip: '192.168.1.103',
            time: '15 minutes ago',
            severity: 'warning'
        }
    ];

    // Mock policy evaluation results
    const policyResults = [
        { policy: 'data-access', allowed: 89, denied: 11, total: 100 },
        { policy: 'admin-access', allowed: 5, denied: 15, total: 20 },
        { policy: 'api-access', allowed: 245, denied: 8, total: 253 },
        { policy: 'resource-access', allowed: 156, denied: 4, total: 160 }
    ];

    const getSeverityColor = (severity) => {
        switch (severity) {
            case 'success': return 'success';
            case 'warning': return 'warning';
            case 'error': return 'error';
            default: return 'default';
        }
    };

    const getSeverityIcon = (severity) => {
        switch (severity) {
            case 'success': return <CheckCircle color="success" />;
            case 'warning': return <Warning color="warning" />;
            case 'error': return <Error color="error" />;
            default: return <CheckCircle />;
        }
    };

    return (
        <Box>
            <Box display="flex" alignItems="center" mb={3}>
                <Security sx={{ fontSize: 40, color: 'primary.main', mr: 2 }} />
                <Typography variant="h4">
                    Security Overview
                </Typography>
            </Box>

            <Alert severity="info" sx={{ mb: 3 }}>
                Real-time security monitoring and threat detection for the Zero Trust environment.
            </Alert>

            <Grid container spacing={3}>
                {/* Security Metrics */}
                <Grid item xs={12} md={8}>
                    <Card>
                        <CardContent>
                            <Typography variant="h6" gutterBottom>
                                Security Metrics
                            </Typography>
                            <Grid container spacing={2}>
                                <Grid item xs={6} sm={3}>
                                    <Box textAlign="center" p={2}>
                                        <Typography variant="h4" color="success.main">
                                            {securityMetrics.authSuccessRate}%
                                        </Typography>
                                        <Typography variant="body2" color="text.secondary">
                                            Auth Success Rate
                                        </Typography>
                                    </Box>
                                </Grid>
                                <Grid item xs={6} sm={3}>
                                    <Box textAlign="center" p={2}>
                                        <Typography variant="h4" color="error.main">
                                            {securityMetrics.authFailures}
                                        </Typography>
                                        <Typography variant="body2" color="text.secondary">
                                            Auth Failures
                                        </Typography>
                                    </Box>
                                </Grid>
                                <Grid item xs={6} sm={3}>
                                    <Box textAlign="center" p={2}>
                                        <Typography variant="h4" color="warning.main">
                                            {securityMetrics.suspiciousActivity}
                                        </Typography>
                                        <Typography variant="body2" color="text.secondary">
                                            Suspicious Events
                                        </Typography>
                                    </Box>
                                </Grid>
                                <Grid item xs={6} sm={3}>
                                    <Box textAlign="center" p={2}>
                                        <Typography variant="h4" color="success.main">
                                            {securityMetrics.activeThreats}
                                        </Typography>
                                        <Typography variant="body2" color="text.secondary">
                                            Active Threats
                                        </Typography>
                                    </Box>
                                </Grid>
                            </Grid>
                        </CardContent>
                    </Card>
                </Grid>

                {/* Certificate Status */}
                <Grid item xs={12} md={4}>
                    <Card>
                        <CardContent>
                            <Typography variant="h6" gutterBottom>
                                Certificate Status
                            </Typography>
                            <Box mb={2}>
                                <Box display="flex" justifyContent="space-between" mb={1}>
                                    <Typography variant="body2">SSL Certificate</Typography>
                                    <Chip
                                        label={securityMetrics.certificateExpiry > 30 ? 'Valid' : 'Expiring Soon'}
                                        size="small"
                                        color={securityMetrics.certificateExpiry > 30 ? 'success' : 'warning'}
                                    />
                                </Box>
                                <LinearProgress
                                    variant="determinate"
                                    value={Math.min((securityMetrics.certificateExpiry / 90) * 100, 100)}
                                    color={securityMetrics.certificateExpiry > 30 ? 'success' : 'warning'}
                                />
                                <Typography variant="caption" color="text.secondary">
                                    Expires in {securityMetrics.certificateExpiry} days
                                </Typography>
                            </Box>
                        </CardContent>
                    </Card>
                </Grid>

                {/* Policy Evaluation Results */}
                <Grid item xs={12} md={6}>
                    <Card>
                        <CardContent>
                            <Typography variant="h6" gutterBottom>
                                Policy Evaluation Results
                            </Typography>
                            <TableContainer component={Paper} variant="outlined">
                                <Table size="small">
                                    <TableHead>
                                        <TableRow>
                                            <TableCell>Policy</TableCell>
                                            <TableCell align="right">Allowed</TableCell>
                                            <TableCell align="right">Denied</TableCell>
                                            <TableCell align="right">Success Rate</TableCell>
                                        </TableRow>
                                    </TableHead>
                                    <TableBody>
                                        {policyResults.map((policy) => (
                                            <TableRow key={policy.policy}>
                                                <TableCell>{policy.policy}</TableCell>
                                                <TableCell align="right">
                                                    <Chip
                                                        label={policy.allowed}
                                                        size="small"
                                                        color="success"
                                                        variant="outlined"
                                                    />
                                                </TableCell>
                                                <TableCell align="right">
                                                    <Chip
                                                        label={policy.denied}
                                                        size="small"
                                                        color="error"
                                                        variant="outlined"
                                                    />
                                                </TableCell>
                                                <TableCell align="right">
                                                    {((policy.allowed / policy.total) * 100).toFixed(1)}%
                                                </TableCell>
                                            </TableRow>
                                        ))}
                                    </TableBody>
                                </Table>
                            </TableContainer>
                        </CardContent>
                    </Card>
                </Grid>

                {/* Recent Security Events */}
                <Grid item xs={12} md={6}>
                    <Card>
                        <CardContent>
                            <Typography variant="h6" gutterBottom>
                                Recent Security Events
                            </Typography>
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
                        </CardContent>
                    </Card>
                </Grid>

                {/* Zero Trust Security Controls */}
                <Grid item xs={12}>
                    <Card>
                        <CardContent>
                            <Typography variant="h6" gutterBottom>
                                Zero Trust Security Controls
                            </Typography>
                            <Grid container spacing={2}>
                                <Grid item xs={12} sm={6} md={3}>
                                    <Box textAlign="center" p={2}>
                                        <Shield sx={{ fontSize: 40, color: 'primary.main', mb: 1 }} />
                                        <Typography variant="subtitle1">Identity Verification</Typography>
                                        <Typography variant="body2" color="text.secondary">
                                            Multi-factor authentication with Keycloak
                                        </Typography>
                                        <Chip label="Active" size="small" color="success" sx={{ mt: 1 }} />
                                    </Box>
                                </Grid>
                                <Grid item xs={12} sm={6} md={3}>
                                    <Box textAlign="center" p={2}>
                                        <Lock sx={{ fontSize: 40, color: 'primary.main', mb: 1 }} />
                                        <Typography variant="subtitle1">Policy Enforcement</Typography>
                                        <Typography variant="body2" color="text.secondary">
                                            OPA policies control all access decisions
                                        </Typography>
                                        <Chip label="Active" size="small" color="success" sx={{ mt: 1 }} />
                                    </Box>
                                </Grid>
                                <Grid item xs={12} sm={6} md={3}>
                                    <Box textAlign="center" p={2}>
                                        <Visibility sx={{ fontSize: 40, color: 'primary.main', mb: 1 }} />
                                        <Typography variant="subtitle1">Continuous Monitoring</Typography>
                                        <Typography variant="body2" color="text.secondary">
                                            Real-time security event monitoring
                                        </Typography>
                                        <Chip label="Active" size="small" color="success" sx={{ mt: 1 }} />
                                    </Box>
                                </Grid>
                                <Grid item xs={12} sm={6} md={3}>
                                    <Box textAlign="center" p={2}>
                                        <Block sx={{ fontSize: 40, color: 'primary.main', mb: 1 }} />
                                        <Typography variant="subtitle1">Threat Prevention</Typography>
                                        <Typography variant="body2" color="text.secondary">
                                            Rate limiting and anomaly detection
                                        </Typography>
                                        <Chip label="Active" size="small" color="success" sx={{ mt: 1 }} />
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

export default SecurityOverview; 