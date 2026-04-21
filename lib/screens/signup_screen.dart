import 'package:flutter/material.dart';

import '../app/blood_type_options.dart';
import '../services/api_service.dart';
import '../widgets/app_logo.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  int? _selectedBloodTypeId;
  String? _selectedGender;
  DateTime? _dateOfBirth;
  DateTime? _lastDonationDate;

  final List<MapEntry<String, String>> _genders = const [
    MapEntry('male', 'ذكر'),
    MapEntry('female', 'أنثى'),
  ];

  bool _isLoading = false;

  final Color primaryRed = const Color(0xFFD32F2F);

  DateTime _maxBirthDate() {
    final now = DateTime.now();
    return DateTime(now.year - 18, now.month, now.day);
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBloodTypeId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اختر فصيلة الدم')));
      return;
    }
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اختر تاريخ الميلاد')));
      return;
    }
    if (_dateOfBirth!.isAfter(_maxBirthDate())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب أن يكون العمر 18 سنة أو أكثر للتبرع'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.signup(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
        bloodTypeId: _selectedBloodTypeId!,
        weight: double.tryParse(_weightController.text.trim()) ?? 0.0,
        dateOfBirth: _dateOfBirth!,
        height: double.tryParse(_heightController.text.trim()),
        gender: _selectedGender,
        lastDonationDate: _formatDate(_lastDonationDate),
      );

      if (!mounted) return;
      final snackMessage =
          (response['message'] as String?) ??
          'تم إنشاء الحساب. أرسلنا رمز التحقق إلى بريدك الإلكتروني.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(snackMessage), backgroundColor: primaryRed),
      );
      Navigator.pushReplacementNamed(
        context,
        '/signup-verify',
        arguments: {'email': _emailController.text.trim()},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل إنشاء الحساب: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
    _heightController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _maxBirthDate(),
      firstDate: DateTime(1940),
      lastDate: _maxBirthDate(),
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _pickLastDonationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _lastDonationDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب'),
        backgroundColor: primaryRed,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const AppLogo(size: 100),
              const SizedBox(height: 20),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم الأول',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'الاسم الأول مطلوب' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'اسم العائلة',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'اسم العائلة مطلوب' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || !v.contains('@') ? 'أدخل بريدًا صحيحًا' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف (10 أرقام)',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'رقم الهاتف مطلوب';
                  if (v.length != 10) {
                    return 'رقم الهاتف يجب أن يكون 10 أرقام';
                  }
                  if (int.tryParse(v) == null) {
                    return 'رقم الهاتف يجب أن يكون أرقامًا فقط';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الوزن (كغ)',
                  prefixIcon: Icon(Icons.monitor_weight),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'الوزن مطلوب';
                  final w = double.tryParse(v);
                  if (w == null) return 'أدخل أرقامًا فقط';
                  if (w < 50) return 'الوزن يجب أن يكون 50 كغ أو أكثر';
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الطول (اختياري)',
                  prefixIcon: Icon(Icons.height),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.length < 8
                    ? 'كلمة المرور 8 أحرف على الأقل'
                    : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'فصيلة الدم',
                  border: OutlineInputBorder(),
                ),
                items: bloodTypeOptions.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedBloodTypeId = val),
                validator: (v) => v == null ? 'اختر فصيلة الدم' : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'الجنس (اختياري)',
                  border: OutlineInputBorder(),
                ),
                items: _genders
                    .map(
                      (g) =>
                          DropdownMenuItem(value: g.key, child: Text(g.value)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedGender = val),
              ),
              const SizedBox(height: 15),
              ListTile(
                title: Text(
                  _dateOfBirth == null
                      ? 'تاريخ الميلاد (مطلوب)'
                      : 'تاريخ الميلاد: ${_formatDate(_dateOfBirth)}',
                ),
                trailing: const Icon(Icons.cake_outlined, color: Colors.red),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                onTap: _pickDateOfBirth,
              ),
              const SizedBox(height: 15),
              ListTile(
                title: Text(
                  _lastDonationDate == null
                      ? 'تاريخ آخر تبرع (اختياري)'
                      : 'آخر تبرع: ${_formatDate(_lastDonationDate)}',
                ),
                trailing: const Icon(Icons.calendar_month, color: Colors.red),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                onTap: _pickLastDonationDate,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'إنشاء حساب',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
