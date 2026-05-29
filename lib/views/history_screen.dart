import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _filter = 'Tout'; // Tout, Transaction, Membre, Note de Frais

  IconData _getIcon(String action) {
    if (action.contains('Transaction')) return Icons.receipt;
    if (action.contains('Membre')) return Icons.person;
    if (action.contains('Note') || action.contains('Frais')) return Icons.receipt_long;
    if (action.contains('Rôle')) return Icons.admin_panel_settings;
    if (action.contains('Suppression')) return Icons.delete;
    return Icons.history;
  }

  Color _getColor(String action) {
    if (action.contains('Suppression')) return Colors.red;
    if (action.contains('Modification')) return Colors.orange;
    if (action.contains('Ajout') || action.contains('Nouvelle')) return Colors.green;
    if (action.contains('Note') || action.contains('Frais')) return Colors.purple;
    return AppColors.primary;
  }

  bool _matchesFilter(String action) {
    if (_filter == 'Tout') return true;
    if (_filter == 'Transaction') return action.contains('Transaction');
    if (_filter == 'Membre') return action.contains('Membre') || action.contains('Rôle');
    if (_filter == 'Note de Frais') return action.contains('Note') || action.contains('Frais');
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Historique de l'Association"),
        backgroundColor: AppColors.secondary,
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey[50],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Tout', 'Transaction', 'Membre', 'Note de Frais'].map((f) {
                  final selected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selected ? AppColors.primary : Colors.grey[700],
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('audit_logs')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Aucun historique pour le moment.'));
                }

                final logs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _matchesFilter(data['action'] ?? '');
                }).toList();

                if (logs.isEmpty) {
                  return Center(child: Text('Aucun événement de ce type.', style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final data = logs[index].data() as Map<String, dynamic>;
                    final action = data['action'] ?? 'Action';
                    final timestamp = data['timestamp'] as Timestamp?;
                    final dateStr = timestamp != null
                        ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
                        : 'Date inconnue';
                    final color = _getColor(action);
                    final icon = _getIcon(action);

                    return Card(
                      margin: EdgeInsets.only(bottom: 10),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 20),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(action,
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                                      ),
                                      Text(dateStr, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(data['details'] ?? '',
                                      style: TextStyle(fontSize: 13, color: Colors.black87)),
                                  SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.person, size: 12, color: Colors.grey),
                                      SizedBox(width: 4),
                                      Text(data['userName'] ?? 'Inconnu',
                                          style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic, fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
