import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DutyPage extends StatelessWidget {
  const DutyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('dd.MM.yyyy').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(title: const Text('Nöbetçi Hizmetler')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Tarih: $today', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          const _DutyCard(
            title: 'Nöbetçi Eczaneler',
            icon: Icons.local_pharmacy,
            note: 'Eczacı Odası verisi + tarih bazlı kayıt',
          ),
          const _DutyCard(
            title: 'Nöbetçi Noterler',
            icon: Icons.description,
            note: 'Gün/tarih bazlı nöbet takvimi',
          ),
        ],
      ),
    );
  }
}

class _DutyCard extends StatelessWidget {
  const _DutyCard({required this.title, required this.icon, required this.note});
  final String title;
  final IconData icon;
  final String note;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon, size: 30),
      title: Text(title),
      subtitle: Text(note),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}
