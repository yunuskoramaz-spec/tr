import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DutyPage extends StatelessWidget {
  const DutyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('dd.MM.yyyy').format(DateTime.now());
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) { if (!didPop) context.go('/'); },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: const Text('Nöbetçi Hizmetler', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500)),
          leading: IconButton(icon: const Icon(Icons.arrow_back, size: 28), onPressed: () => context.go('/')),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Container(width: 50, height: 50, decoration: BoxDecoration(color: const Color(0xFFE5F8F3), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.calendar_today_outlined, color: Color(0xFF2DBF9E))),
                  const SizedBox(width: 14),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Bugünün nöbetçi yerleri', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)), SizedBox(height: 4), Text('Güncel veri kaynağına göre kontrol edilir.')])) ,
                  Text(today, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF5D748A))),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            _DutyCard(title: 'Nöbetçi Eczaneler', icon: Icons.local_pharmacy_outlined, color: const Color(0xFF2DBF9E), note: 'İsim, adres, telefon ve yol tarifi ile liste görünümü.'),
            _DutyCard(title: 'Nöbetçi Noterler', icon: Icons.description_outlined, color: const Color(0xFF3978D5), note: 'Nöbet bilgisi mevcut olduğunda tarih bazlı gösterilir.'),
          ],
        ),
      ),
    );
  }
}

class _DutyCard extends StatelessWidget {
  const _DutyCard({required this.title, required this.icon, required this.color, required this.note});
  final String title, note; final IconData icon; final Color color;
  @override Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12), elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: Container(width: 52, height: 52, decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color, size: 28)),
      title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(note)),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}
