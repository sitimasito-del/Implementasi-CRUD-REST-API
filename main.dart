import 'package:flutter/material.dart';
import 'package:tugas_p5_crud/models/user_model.dart';
import 'package:tugas_p5_crud/services/user_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CRUD Reqres.in',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const UserPage(),
    );
  }
}

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final UserService _userService = UserService();
  late Future<void> _userFuture;
  List<UserModel> _users = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jobController.dispose();
    super.dispose();
  }

  // Data awal diambil dari reqres.in (GET), disimpan di list lokal.
  Future<void> _loadUsers() async {
    _users = await _userService.getUsers();
  }

  void _refreshUsers() {
    setState(() {
      _userFuture = _loadUsers();
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _errorText(Object e) => e.toString().replaceAll('Exception: ', '');

  void _showFormDialog({UserModel? user}) {
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    if (user != null) {
      _nameController.text = user.firstName;
      _jobController.text = 'Developer';
    } else {
      _nameController.clear();
      _jobController.clear();
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(user == null ? 'Tambah User Baru' : 'Edit User'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nama',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nama tidak boleh kosong.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _jobController,
                  decoration: const InputDecoration(
                    labelText: 'Pekerjaan',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Pekerjaan tidak boleh kosong.'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  isSubmitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      final name = _nameController.text.trim();
                      final job = _jobController.text.trim();
                      setDialogState(() => isSubmitting = true);

                      try {
                        if (user == null) {
                          final newUser =
                              await _userService.createUser(name, job);
                          if (!mounted) return;
                          setState(() => _users.insert(0, newUser));
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          _showSnackBar('User $name berhasil ditambahkan!');
                        } else {
                          await _userService.updateUser(user.id, name, job);
                          if (!mounted) return;
                          setState(() {
                            final index = _users
                                .indexWhere((item) => item.id == user.id);
                            if (index != -1) {
                              _users[index] = UserModel(
                                id: user.id,
                                email: user.email,
                                firstName: name,
                                lastName: '',
                                avatar: user.avatar,
                              );
                            }
                          });
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          _showSnackBar(
                            'User ID ${user.id} berhasil diperbarui!',
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          _showSnackBar(_errorText(e), isError: true);
                        }
                        if (dialogContext.mounted) {
                          setDialogState(() => isSubmitting = false);
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUser(UserModel user) async {
    try {
      final success = await _userService.deleteUser(user.id);
      if (success && mounted) {
        setState(() => _users.removeWhere((item) => item.id == user.id));
        _showSnackBar('User ID ${user.id} berhasil dihapus!');
      }
    } catch (e) {
      if (mounted) _showSnackBar(_errorText(e), isError: true);
    }
  }

  Widget _buildUserTile(UserModel user) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Image.network(
            user.avatar,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const CircleAvatar(child: Icon(Icons.person)),
          ),
        ),
        title: Text(
          '${user.firstName} ${user.lastName}'.trim(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(user.email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showFormDialog(user: user),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteUser(user),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRUD REST API - Reqres.in'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUsers,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _errorText(snapshot.error!),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: _refreshUsers,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (_users.isEmpty) {
            return const Center(child: Text('Data user kosong.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _users.length,
            itemBuilder: (context, index) => _buildUserTile(_users[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah User'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }
}