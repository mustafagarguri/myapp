import 'package:flutter/material.dart';

import 'package:myapp/services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _weightController;

  int? _selectedBloodTypeId;
  DateTime? _dateOfBirth;

  final Map<int, String> _bloodTypes = const {
    1: 'A+',
    2: 'A-',
    3: 'B+',
    4: 'B-',
    5: 'O+',
    6: 'O-',
    7: 'AB+',
    8: 'AB-',
  };

  final Color primaryRed = const Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _weightController = TextEditingController();

    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.getUserProfile();
      final user = _extractUser(response);

      if (!mounted) return;
      setState(() {
        _firstNameController.text = (user['first_name'] as String?) ?? '';
        _lastNameController.text = (user['last_name'] as String?) ?? '';
        _emailController.text = (user['email'] as String?) ?? '';
        _phoneController.text = (user['phone_number'] as String?) ?? '';
        _weightController.text = '${user['weight'] ?? ''}';

        final bloodType = user['blood_type'];
        if (bloodType is Map<String, dynamic>) {
          _selectedBloodTypeId = (bloodType['id'] as num?)?.toInt();
        } else {
          _selectedBloodTypeId = (user['blood_type_id'] as num?)?.toInt();
        }

        final dob = user['date_of_birth'];
        if (dob is String && dob.isNotEmpty) {
          _dateOfBirth = DateTime.tryParse(dob);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل جلب البيانات: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, dynamic> _extractUser(Map<String, dynamic> response) {
    final user = response['user'];
    if (user is Map<String, dynamic>) return user;

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      final nested = data['user'];
      if (nested is Map<String, dynamic>) return nested;
      return data;
    }

    return response;
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBloodTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر فصيلة الدم')),
      );
      return;
    }
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تاريخ الميلاد مطلوب')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ApiService.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        weight: double.parse(_weightController.text.trim()),
        bloodTypeId: _selectedBloodTypeId!,
        dateOfBirth: _dateOfBirth!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث الملف الشخصي بنجاح.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل تحديث الملف الشخصي: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: primaryRed,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryRed))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildHeaderAvatar(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('المعلومات الأساسية'),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: _customInputDecoration('الاسم الأول', Icons.person_outline),
                      validator: (v) => v == null || v.isEmpty ? 'هذا الحقل مطلوب' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: _customInputDecoration('اسم العائلة', Icons.badge_outlined),
                      validator: (v) => v == null || v.isEmpty ? 'هذا الحقل مطلوب' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _emailController,
                      readOnly: true,
                      decoration: _customInputDecoration('البريد الإلكتروني', Icons.email_outlined),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _customInputDecoration('رقم الهاتف', Icons.phone_android_outlined),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'هذا الحقل مطلوب';
                        if (v.length != 10) return 'رقم الهاتف يجب أن يكون 10 أرقام';
                        if (int.tryParse(v) == null) return 'أرقام فقط';
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildWeightAndBloodRow(),
                    const SizedBox(height: 25),
                    _buildSectionTitle('البيانات الصحية'),
                    _buildDatePicker(),
                    const SizedBox(height: 40),
                    _buildSaveButton(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderAvatar() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryRed,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
      ),
      child: Center(
        child: Stack(
          children: [
            const CircleAvatar(
              radius: 55,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 51,
                backgroundColor: Color(0xFFEEEEEE),
                child: Icon(Icons.person, size: 65, color: Colors.grey),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 4,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 18,
                child: Icon(Icons.camera_alt, size: 18, color: primaryRed),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 10),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildWeightAndBloodRow() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: _customInputDecoration('الوزن (كغ)', Icons.monitor_weight_outlined),
            validator: (v) {
              if (v == null || v.isEmpty) return 'هذا الحقل مطلوب';
              final w = double.tryParse(v);
              if (w == null) return 'أرقام فقط';
              if (w < 50) return 'الوزن يجب أن يكون 50 كغ أو أكثر';
              return null;
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: _selectedBloodTypeId,
            decoration: _customInputDecoration('فصيلة الدم', Icons.bloodtype_outlined),
            items: _bloodTypes.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (val) => setState(() => _selectedBloodTypeId = val),
            validator: (v) => v == null ? 'اختر فصيلة الدم' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _pickDateOfBirth,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Icon(Icons.cake_outlined, color: primaryRed, size: 20),
            const SizedBox(width: 12),
            Text(
              _dateOfBirth == null
                  ? 'تاريخ الميلاد'
                  : 'تاريخ الميلاد: ${_formatDate(_dateOfBirth)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('حفظ التغييرات', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  InputDecoration _customInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryRed, size: 22),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade100),
      ),
    );
  }
}

