import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  late Future<UserProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _apiService.getProfile();
  }

  Future<void> _handleLogout(BuildContext context) async {
    await _apiService.logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openEditDialog(UserProfile profile) {
    final nameController = TextEditingController(text: profile.fullName);
    final phoneController = TextEditingController(
      text: profile.phoneNumber ?? '',
    );
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Profil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      try {
                        await _apiService.updateProfile(
                          fullName: nameController.text.trim(),
                          phoneNumber: phoneController.text.trim(),
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        setState(() {
                          _profileFuture = _apiService.getProfile();
                        });
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: FutureBuilder<UserProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal memuat profil: ${snapshot.error}'),
            );
          }

          final profile = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 16),
              const CircleAvatar(
                radius: 48,
                child: Icon(Icons.person, size: 48),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  profile.fullName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  profile.email,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 32),

              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('Nomor Telepon'),
                subtitle: Text(
                  profile.phoneNumber?.isNotEmpty == true
                      ? profile.phoneNumber!
                      : 'Belum diisi',
                ),
              ),
              const Divider(),

              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Profil'),
                onTap: () => _openEditDialog(profile),
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Keluar',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => _handleLogout(context),
              ),
            ],
          );
        },
      ),
    );
  }
}
