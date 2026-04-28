import 'package:flutter/material.dart';
import 'package:blue_cash/core/theme/app_color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  final String name;
  final String email;

  const EditProfileScreen({
    super.key,
    required this.name,
    required this.email,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    emailController = TextEditingController(text: widget.email);
  }

  Future<bool> _reauthenticateUser(String oldPassword) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      AuthCredential credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateProfile() async {
    if (newPasswordController.text.isNotEmpty) {
      if (oldPasswordController.text.isEmpty) {
        _showSnackBar("Please enter your old password first");
        return;
      }
      if (newPasswordController.text != confirmPasswordController.text) {
        _showSnackBar("New passwords do not match!");
        return;
      }
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      if (newPasswordController.text.isNotEmpty || emailController.text.trim() != widget.email) {
        bool authSuccess = await _reauthenticateUser(oldPasswordController.text.trim());
        if (!authSuccess) {
          _showSnackBar("Incorrect old password!");
          setState(() => isLoading = false);
          return;
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
      });

      await user.updateDisplayName(nameController.text.trim());

      if (newPasswordController.text.isNotEmpty) {
        await user.updatePassword(newPasswordController.text.trim());
      }

      if (emailController.text.trim() != widget.email) {
        await user.verifyBeforeUpdateEmail(emailController.text.trim());
      }

      if (mounted) {
        _showSnackBar("Profile Updated Successfully!", isError: false);
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Header Background
          Container(
            height: 260,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.blue, AppColors.blue],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        "Edit Profile",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Form Container
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Personal Information"),
                          TextField(
                            controller: nameController,
                            decoration: _inputStyle("Name"),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: emailController,
                            decoration: _inputStyle("Email"),
                          ),

                          const SizedBox(height: 30),
                          _buildLabel("Security & Password"),
                          TextField(
                            controller: oldPasswordController,
                            obscureText: true,
                            decoration: _inputStyle("Old Password"),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: newPasswordController,
                            obscureText: true,
                            decoration: _inputStyle("New Password"),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: confirmPasswordController,
                            obscureText: true,
                            decoration: _inputStyle("Confirm New Password"),
                          ),

                          const SizedBox(height: 40),

                          // Save Button (Same style as Financial Management)
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              )
                                  : const Text(
                                "Save Changes",
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // المكونات المساعدة من Financial Management
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none
      ),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200)
      ),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5)
      ),
    );
  }
}