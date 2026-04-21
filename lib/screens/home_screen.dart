import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:myapp/features/calls/domain/call_status.dart';
import 'package:myapp/features/calls/presentation/call_state.dart';
import 'package:myapp/services/api_service.dart';
import 'package:myapp/widgets/app_logo.dart';

import 'home_tips.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = '';
  String userBloodType = '';
  bool isEligible = true;
  DateTime? nextEligibleDate;
  int? remainingDays;
  bool isLoading = true;

  final Color primaryRed = const Color(0xFFD32F2F);
  final Color statusGreen = const Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() => isLoading = true);

    try {
      final response = await ApiService.getUserProfile();
      final user = _extractUser(response);

      if (!mounted) return;
      setState(() {
        final first = (user['first_name'] as String?) ?? '';
        final last = (user['last_name'] as String?) ?? '';
        userName = '$first $last'.trim().isEmpty
            ? 'المستخدم'
            : '$first $last'.trim();

        final bloodType = user['blood_type'];
        if (bloodType is Map<String, dynamic>) {
          userBloodType = (bloodType['name'] as String?) ?? '--';
        } else {
          userBloodType = (user['blood_type'] as String?) ?? '--';
        }

        final isAvailable = (user['is_available'] as bool?) ?? false;
        final nextRaw = (user['next_eligible_date'] as String?) ?? '';
        DateTime? parsedNext;
        if (nextRaw.trim().isNotEmpty) {
          parsedNext = DateTime.tryParse(nextRaw);
        }

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final normalizedNext = parsedNext == null
            ? null
            : DateTime(parsedNext.year, parsedNext.month, parsedNext.day);

        final eligible =
            isAvailable &&
            (normalizedNext == null || !normalizedNext.isAfter(today));
        int? daysRemaining;
        if (!eligible &&
            normalizedNext != null &&
            normalizedNext.isAfter(today)) {
          daysRemaining = normalizedNext.difference(today).inDays;
        }

        isEligible = eligible;
        nextEligibleDate = normalizedNext;
        remainingDays = daysRemaining;
      });

      if (mounted) {
        await context.read<CallState>().loadActiveCall();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل تحميل الملف الشخصي: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
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

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: const Text(
          'وريد',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      drawer: _buildDrawer(context),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryRed))
          : RefreshIndicator(
              onRefresh: _fetchUserData,
              child: ListView(
                children: [
                  _buildHeroSection(),
                  _buildTipSection(),
                  _buildActiveCallSection(),
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      'لا توجد نداءات عامة متاحة حاليًا. عند توفر حاجة متوافقة معك سنقوم بإشعارك مباشرة.',
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildActiveCallSection() {
    return Consumer<CallState>(
      builder: (context, callState, _) {
        final activeCall = callState.activeCall;
        if (activeCall == null && callState.error != null) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('تعذر تحميل النداء النشط: ${callState.error}'),
                ),
                TextButton(
                  onPressed: _fetchUserData,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }
        if (activeCall == null) {
          return const SizedBox.shrink();
        }

        final goToTracking =
            activeCall.myStatus == CallStatus.accepted ||
            activeCall.myStatus == CallStatus.checkedIn ||
            activeCall.myStatus == CallStatus.arrived;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ندائي النشط',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 8),
              Text('المستشفى: ${activeCall.hospitalName}'),
              Text('فصيلة الدم: ${activeCall.bloodType}'),
              Text('حالتك: ${activeCall.myStatus.labelAr}'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/call-details',
                          arguments: {'callId': activeCall.id},
                        );
                      },
                      child: const Text('فتح التفاصيل'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          goToTracking ? '/call-tracking' : '/call-details',
                          arguments: {'callId': activeCall.id},
                        );
                      },
                      child: Text(
                        goToTracking ? 'متابعة الالتزام' : 'الرد الآن',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTipSection() {
    return Consumer<CallState>(
      builder: (context, callState, _) {
        final tip = selectHomeTip(
          now: DateTime.now(),
          isEligible: isEligible,
          hasActiveCall: callState.activeCall != null,
        );

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.red.shade50,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.favorite_outline, color: primaryRed),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نصيحة اليوم',
                      style: TextStyle(
                        color: primaryRed,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tip.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tip.body,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isEligible
              ? [statusGreen.withValues(alpha: 0.8), statusGreen]
              : [Colors.orange.withValues(alpha: 0.8), Colors.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: (isEligible ? statusGreen : Colors.orange).withValues(
              alpha: 0.3,
            ),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const AppLogo(size: 64),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً، $userName',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  () {
                    if (isEligible) {
                      return 'أنت مؤهل للتبرع اليوم.';
                    }

                    if (nextEligibleDate != null) {
                      final dateText = _formatDate(nextEligibleDate!);
                      final remaining = remainingDays != null
                          ? 'متبقي $remainingDays يوم'
                          : 'غير مؤهل حالياً';
                      return '$remaining (الموعد القادم: $dateText).';
                    }

                    return 'أنت غير متاح للتبرع حالياً.';
                  }(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: primaryRed),
            accountName: Text(
              userName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text('فصيلة الدم: $userBloodType'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFFD32F2F), size: 45),
            ),
          ),
          ListTile(
            leading: Icon(Icons.person_outline, color: primaryRed),
            title: const Text('تعديل الملف الشخصي'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/edit-profile');
            },
          ),
          ListTile(
            leading: Icon(Icons.history, color: primaryRed),
            title: const Text('سجل التبرعات'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/donation-history');
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.grey),
            title: const Text('تسجيل الخروج'),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
