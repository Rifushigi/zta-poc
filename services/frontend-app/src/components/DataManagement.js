import React, { useState, useEffect } from 'react';
import {
    Box,
    Card,
    CardContent,
    Typography,
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
    IconButton,
    Chip,
    Alert,
    CircularProgress,
    Pagination,
    Fab
} from '@mui/material';
import {
    Add,
    Edit,
    Delete,
    Visibility,
    Refresh
} from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from 'axios';

const DataManagement = () => {
    const { getToken } = useAuth();
    const queryClient = useQueryClient();
    const [page, setPage] = useState(1);
    const [limit] = useState(10);
    const [openDialog, setOpenDialog] = useState(false);
    const [editingItem, setEditingItem] = useState(null);
    const [formData, setFormData] = useState({ name: '', description: '' });

    // API configuration
    const api = axios.create({
        baseURL: process.env.REACT_APP_API_URL || 'http://localhost:8000',
        withCredentials: true
    });

    // Fetch data
    const { data, isLoading, error, refetch } = useQuery(
        ['items', page, limit],
        async () => {
            const response = await api.get(`/api/data?page=${page}&limit=${limit}`);
            return response.data;
        },
        {
            retry: 1,
            onError: (error) => {
                console.error('Failed to fetch data:', error);
            }
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

    const handlePageChange = (event, value) => {
        setPage(value);
    };

    if (error) {
        return (
            <Box>
                <Alert severity="error" sx={{ mb: 2 }}>
                    Failed to load data. Please check your authentication and try again.
                </Alert>
                <Button
                    variant="contained"
                    startIcon={<Refresh />}
                    onClick={() => refetch()}
                >
                    Retry
                </Button>
            </Box>
        );
    }

    return (
        <Box>
            <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
                <Typography variant="h4">
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

            <Alert severity="info" sx={{ mb: 3 }}>
                This demonstrates role-based access control. Users can only view and manage their own data.
                Admins can access all data through the Admin Panel.
            </Alert>

            <Card>
                <CardContent>
                    {isLoading ? (
                        <Box display="flex" justifyContent="center" p={3}>
                            <CircularProgress />
                        </Box>
                    ) : (
                        <>
                            <TableContainer component={Paper} variant="outlined">
                                <Table>
                                    <TableHead>
                                        <TableRow>
                                            <TableCell>Name</TableCell>
                                            <TableCell>Description</TableCell>
                                            <TableCell>Owner</TableCell>
                                            <TableCell>Created</TableCell>
                                            <TableCell>Actions</TableCell>
                                        </TableRow>
                                    </TableHead>
                                    <TableBody>
                                        {data?.items?.map((item) => (
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
                                                    <IconButton
                                                        size="small"
                                                        onClick={() => handleOpenDialog(item)}
                                                        color="primary"
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

                            {data?.pagination && (
                                <Box display="flex" justifyContent="center" mt={3}>
                                    <Pagination
                                        count={data.pagination.pages}
                                        page={page}
                                        onChange={handlePageChange}
                                        color="primary"
                                    />
                                </Box>
                            )}
                        </>
                    )}
                </CardContent>
            </Card>

            {/* Add/Edit Dialog */}
            <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
                <DialogTitle>
                    {editingItem ? 'Edit Item' : 'Add New Item'}
                </DialogTitle>
                <form onSubmit={handleSubmit}>
                    <DialogContent>
                        <TextField
                            autoFocus
                            margin="dense"
                            label="Name"
                            fullWidth
                            variant="outlined"
                            value={formData.name}
                            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                            required
                            sx={{ mb: 2 }}
                        />
                        <TextField
                            margin="dense"
                            label="Description"
                            fullWidth
                            variant="outlined"
                            multiline
                            rows={3}
                            value={formData.description}
                            onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                            required
                        />
                    </DialogContent>
                    <DialogActions>
                        <Button onClick={handleCloseDialog}>Cancel</Button>
                        <Button
                            type="submit"
                            variant="contained"
                            disabled={createMutation.isLoading || updateMutation.isLoading}
                        >
                            {createMutation.isLoading || updateMutation.isLoading ? (
                                <CircularProgress size={20} />
                            ) : (
                                editingItem ? 'Update' : 'Create'
                            )}
                        </Button>
                    </DialogActions>
                </form>
            </Dialog>
        </Box>
    );
};

export default DataManagement; 