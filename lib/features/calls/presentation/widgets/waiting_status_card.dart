import 'package:flutter/material.dart';

class WaitingStatusCard extends StatelessWidget {
  const WaitingStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: const Row(
        children: [
          Icon(Icons.hourglass_top_rounded, color: Colors.amber),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'أنت ضمن قائمة الانتظار الآن. سيتم إشعارك فور الحاجة لك.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
