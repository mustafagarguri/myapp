import 'package:flutter/material.dart';

import '../services/api_service.dart';

class DonationLedgerEntry {
  const DonationLedgerEntry({
    required this.callId,
    required this.hospitalName,
    required this.bloodType,
    required this.donatedAt,
  });

  final int callId;
  final String hospitalName;
  final String bloodType;
  final DateTime? donatedAt;

  factory DonationLedgerEntry.fromJson(Map<String, dynamic> json) {
    final donatedAtRaw =
        (json['donated_at'] ?? json['donation_date']) as String?;
    return DonationLedgerEntry(
      callId:
          (json['call_id'] as num?)?.toInt() ??
          (json['id'] as num?)?.toInt() ??
          0,
      hospitalName: (json['hospital_name'] as String?) ?? 'غير معروف',
      bloodType: (json['blood_type'] as String?) ?? '--',
      donatedAt: donatedAtRaw == null ? null : DateTime.tryParse(donatedAtRaw),
    );
  }
}

class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({super.key});

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<DonationLedgerEntry> _entries = const [];

  @override
  void initState() {
    super.initState();
    _loadLedger();
  }

  Future<void> _loadLedger() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await ApiService.getDonationLedger();
      final items = raw.map(DonationLedgerEntry.fromJson).toList();
      if (!mounted) return;
      setState(() => _entries = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل التبرعات')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('تعذر تحميل السجل: $_error'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadLedger,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            )
          : _entries.isEmpty
          ? const Center(child: Text('لا توجد تبرعات مسجلة بعد.'))
          : RefreshIndicator(
              onRefresh: _loadLedger,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final item = _entries[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المستشفى: ${item.hospitalName}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text('فصيلة الدم: ${item.bloodType}'),
                        const SizedBox(height: 6),
                        Text('تاريخ التبرع: ${_formatDate(item.donatedAt)}'),
                      ],
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: _entries.length,
              ),
            ),
    );
  }
}
