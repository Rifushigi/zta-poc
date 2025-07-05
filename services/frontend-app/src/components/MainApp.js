import React, { useState } from 'react';
import {
    Box,
    AppBar,
    Toolbar,
    Typography,
    IconButton,
    Avatar,
    Menu,
    MenuItem,
    Chip,
    Tabs,
    Tab,
    Card,
    CardContent,
    Grid,
    Button,
    TextField,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    Paper,
    Alert,
    CircularProgress,
    List,
    ListItem,
    ListItemText,
    ListItemIcon,
    Divider
} from '@mui/material';
import {
    Dashboard,
    DataUsage,
    AdminPanelSettings,
    Person,
    Logout,
    Add,
    Edit,
    Delete,
    Refresh,
    CheckCircle,
    Warning,
    Error,
    Schedule
} from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../utils/api';

const MainApp = () => {
    const { user, logout } = useAuth();
    const queryClient = useQueryClient();
    const [activeTab, setActiveTab] = useState(0);
    const [anchorEl, setAnchorEl] = useState(null);
    const [openDialog, setOpenDialog] = useState(false);
    const [editingItem, setEditingItem] = useState(null);
    const [formData, setFormData] = useState({ name: '', description: '' });
    // Fetch data
    const { data, isLoading, error, refetch } = useQuery(
        ['items'],
        async () => {
            const response = await api.get('/api/data?page=1&limit=50');
            return response.data;
        },
        {
            retry: 1,
            onError: (error) => {
                console.error('Failed to fetch data:', error);
            }
        }
    );

    // Fetch admin data
    const { data: adminData, isLoading: adminLoading, error: adminError } = useQuery(
        ['admin-data'],
        async () => {
            const response = await api.get('/api/admin?page=1&limit=50');
            return response.data;
        },
        {
            retry: 1,
            onError: (error) => {
                console.error('Failed to fetch admin data:', error);
            },
            enabled: user?.roles?.includes('admin')
        }
    );

    // Create mutation
    const createMutation = useMutation(
        async (newItem) => {
            const response = await api.post('/api/data', newItem);
            return response.data;
        },
        {
            onSuccess: () => {
                queryClient.invalidateQueries(['items']);
                setOpenDialog(false);
                setFormData({ name: '', description: '' });
            }
        }
    );

    // Update mutation
    const updateMutation = useMutation(
        async (updatedItem) => {
            const response = await api.put(`/api/data/${updatedItem.id}`, updatedItem);
            return response.data;
        },
        {
            onSuccess: () => {
                queryClient.invalidateQueries(['items']);
                setOpenDialog(false);
                setEditingItem(null);
                setFormData({ name: '', description: '' });
            }
        }
    );

    // Delete mutation
    const deleteMutation = useMutation(
        async (id) => {
            await api.delete(`/api/data/${id}`);
        },
        {
            onSuccess: () => {
                queryClient.invalidateQueries(['items']);
            }
        }
    );

    const handleMenuOpen = (event) => {
        setAnchorEl(event.currentTarget);
    };

    const handleMenuClose = () => {
        setAnchorEl(null);
    };

    const handleLogout = () => {
        handleMenuClose();
        logout();
    };

    const handleOpenDialog = (item = null) => {
        if (item) {
            setEditingItem(item);
            setFormData({ name: item.name, description: item.description });
        } else {
            setEditingItem(null);
            setFormData({ name: '', description: '' });
        }
        setOpenDialog(true);
    };

    const handleCloseDialog = () => {
        setOpenDialog(false);
        setEditingItem(null);
        setFormData({ name: '', description: '' });
    };

    const handleSubmit = (e) => {
        e.preventDefault();
        if (editingItem) {
            updateMutation.mutate({ ...editingItem, ...formData });
        } else {
            createMutation.mutate(formData);
        }
    };

    const handleDelete = (id) => {
        if (window.confirm('Are you sure you want to delete this item?')) {
            deleteMutation.mutate(id);
        }
    };

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

    // Mock system metrics
    const systemMetrics = {
        totalUsers: 15,
        activeUsers: 8,
        totalItems: data?.items?.length || 0,
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

    const TabPanel = ({ children, value, index }) => (
        <div hidden={value !== index} style={{ paddingTop: 20 }}>
            {value === index && children}
        </div>
    );

    return (
        <Box sx={{ display: 'flex', flexDirection: 'column', minHeight: '100vh' }}>
            {/* Header */}
            <AppBar position="static" sx={{ backgroundColor: 'background.paper', color: 'text.primary' }}>
                <Toolbar>
                    <Typography variant="h6" sx={{ flexGrow: 1 }}>
                        Zero Trust Application
                    </Typography>

                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                        {user?.roles?.map(role => (
                            <Chip
                                key={role}
                                label={role}
                                size="small"
                                color="primary"
                                variant="outlined"
                            />
                        ))}
                        <IconButton onClick={handleMenuOpen}>
                            <Avatar sx={{ width: 32, height: 32, bgcolor: 'primary.main' }}>
                                <Person />
                            </Avatar>
                        </IconButton>
                    </Box>
                </Toolbar>
            </AppBar>

            {/* User Menu */}
            <Menu
                anchorEl={anchorEl}
                open={Boolean(anchorEl)}
                onClose={handleMenuClose}
            >
                <MenuItem>
                    <Typography variant="body2">
                        {user?.username || 'User'}
                    </Typography>
                </MenuItem>
                <Divider />
                <MenuItem onClick={handleLogout}>
                    <Logout sx={{ mr: 1 }} />
                    Logout
                </MenuItem>
            </Menu>

            {/* Main Content */}
            <Box sx={{ flex: 1, p: 3 }}>
                {/* Tabs */}
                <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 3 }}>
                    <Tabs value={activeTab} onChange={(e, newValue) => setActiveTab(newValue)}>
                        <Tab icon={<Dashboard />} label="Dashboard" />
                        <Tab icon={<DataUsage />} label="Data Management" />
                        {user?.roles?.includes('admin') && (
                            <Tab icon={<AdminPanelSettings />} label="Admin Panel" />
                        )}
                    </Tabs>
                </Box>

                {/* Dashboard Tab */}
                <TabPanel value={activeTab} index={0}>
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

                        {/* Security Events */}
                        <Grid item xs={12} md={4}>
                            <Card>
                                <CardContent>
                                    <Typography variant="h6" gutterBottom>
                                        Recent Security Events
                                    </Typography>
                                    <List>
                                        {securityEvents.map((event) => (
                                            <ListItem key={event.id} dense>
                                                <ListItemIcon>
                                                    {getSeverityIcon(event.severity)}
                                                </ListItemIcon>
                                                <ListItemText
                                                    primary={event.event}
                                                    secondary={`${event.user} • ${event.time}`}
                                                />
                                            </ListItem>
                                        ))}
                                    </List>
                                </CardContent>
                            </Card>
                        </Grid>
                    </Grid>
                </TabPanel>

                {/* Data Management Tab */}
                <TabPanel value={activeTab} index={1}>
                    <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
                        <Typography variant="h5">
                            Data Management
                        </Typography>
                        <Button
                            variant="contained"
                            startIcon={<Add />}
                            onClick={() => handleOpenDialog()}
                        >
                            Add New Item
                        </Button>
                    </Box>

                    {error ? (
                        <Alert severity="error" sx={{ mb: 2 }}>
                            Failed to load data. Please check your authentication and try again.
                        </Alert>
                    ) : (
                        <Card>
                            <CardContent>
                                {isLoading ? (
                                    <Box display="flex" justifyContent="center" p={3}>
                                        <CircularProgress />
                                    </Box>
                                ) : (
                                    <TableContainer component={Paper} variant="outlined">
                                        <Table>
                                            <TableHead>
                                                <TableRow>
                                                    <TableCell>Name</TableCell>
                                                    <TableCell>Description</TableCell>
                                                    <TableCell>Owner</TableCell>
                                                    <TableCell>Created</TableCell>
                                                    <TableCell align="right">Actions</TableCell>
                                                </TableRow>
                                            </TableHead>
                                            <TableBody>
                                                {data?.items?.map((item) => (
                                                    <TableRow key={item.id}>
                                                        <TableCell>{item.name}</TableCell>
                                                        <TableCell>{item.description}</TableCell>
                                                        <TableCell>{item.owner}</TableCell>
                                                        <TableCell>
                                                            {new Date(item.createdAt).toLocaleDateString()}
                                                        </TableCell>
                                                        <TableCell align="right">
                                                            <IconButton
                                                                size="small"
                                                                onClick={() => handleOpenDialog(item)}
                                                            >
                                                                <Edit />
                                                            </IconButton>
                                                            <IconButton
                                                                size="small"
                                                                onClick={() => handleDelete(item.id)}
                                                                color="error"
                                                            >
                                                                <Delete />
                                                            </IconButton>
                                                        </TableCell>
                                                    </TableRow>
                                                ))}
                                            </TableBody>
                                        </Table>
                                    </TableContainer>
                                )}
                            </CardContent>
                        </Card>
                    )}
                </TabPanel>

                {/* Admin Panel Tab */}
                {user?.roles?.includes('admin') && (
                    <TabPanel value={activeTab} index={2}>
                        <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
                            <Typography variant="h5">
                                Admin Panel
                            </Typography>
                            <Button
                                variant="outlined"
                                startIcon={<Refresh />}
                                onClick={() => refetch()}
                            >
                                Refresh
                            </Button>
                        </Box>

                        <Alert severity="warning" sx={{ mb: 3 }}>
                            This panel is restricted to administrators only. All actions are logged and audited.
                        </Alert>

                        {adminError ? (
                            <Alert severity="error" sx={{ mb: 2 }}>
                                Failed to load admin data.
                            </Alert>
                        ) : (
                            <Card>
                                <CardContent>
                                    {adminLoading ? (
                                        <Box display="flex" justifyContent="center" p={3}>
                                            <CircularProgress />
                                        </Box>
                                    ) : (
                                        <TableContainer component={Paper} variant="outlined">
                                            <Table>
                                                <TableHead>
                                                    <TableRow>
                                                        <TableCell>Name</TableCell>
                                                        <TableCell>Description</TableCell>
                                                        <TableCell>Owner</TableCell>
                                                        <TableCell>Created</TableCell>
                                                    </TableRow>
                                                </TableHead>
                                                <TableBody>
                                                    {adminData?.items?.map((item) => (
                                                        <TableRow key={item.id}>
                                                            <TableCell>{item.name}</TableCell>
                                                            <TableCell>{item.description}</TableCell>
                                                            <TableCell>{item.owner}</TableCell>
                                                            <TableCell>
                                                                {new Date(item.createdAt).toLocaleDateString()}
                                                            </TableCell>
                                                        </TableRow>
                                                    ))}
                                                </TableBody>
                                            </Table>
                                        </TableContainer>
                                    )}
                                </CardContent>
                            </Card>
                        )}
                    </TabPanel>
                )}
            </Box>

            {/* Add/Edit Dialog */}
            <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
                <DialogTitle>
                    {editingItem ? 'Edit Item' : 'Add New Item'}
                </DialogTitle>
                <DialogContent>
                    <Box component="form" onSubmit={handleSubmit} sx={{ mt: 2 }}>
                        <TextField
                            fullWidth
                            label="Name"
                            value={formData.name}
                            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                            margin="normal"
                            required
                        />
                        <TextField
                            fullWidth
                            label="Description"
                            value={formData.description}
                            onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                            margin="normal"
                            multiline
                            rows={3}
                        />
                    </Box>
                </DialogContent>
                <DialogActions>
                    <Button onClick={handleCloseDialog}>Cancel</Button>
                    <Button
                        onClick={handleSubmit}
                        variant="contained"
                        disabled={!formData.name.trim()}
                    >
                        {editingItem ? 'Update' : 'Create'}
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default MainApp; 