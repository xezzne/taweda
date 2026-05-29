import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:math';
import '../models/user_model.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../services/audit_service.dart';
import '../providers/category_provider.dart';
import '../providers/member_provider.dart';
import '../providers/transaction_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  @override
  _AdminUsersScreenState createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _generateRandomPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$&*';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(10, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<void> _sendEmailJS(String toEmail, String password, String firstName) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'service_id': 'service_uc71t99',
        'template_id': 'template_3j0cz2i',
        'user_id': '2R7LZ0L10P0cOFsZi',
        'template_params': {
          'to_email': toEmail,
          'to_name': firstName,
          'password': password,
          'app_url': 'https://taweda-app.vercel.app',
          'message': 'Voici vos informations d\'accès pour l\'application Tawerda :\n\nLien : https://taweda-app.vercel.app\nMot de passe temporaire : $password\n\n(Si vous avez reçu un bilan financier mensuel, vous pouvez ignorer le mot de passe.)',
        }
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('EmailJS (${response.statusCode}): ${response.body}');
    }
  }

  void _addUser() {
    final _firstNameController = TextEditingController();
    final _lastNameController = TextEditingController();
    final _emailController = TextEditingController();
    final _quotaController = TextEditingController(text: '0');
    String _selectedRole = 'Observateur';
    bool _isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Ajouter Utilisateur / Accès'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: _firstNameController, decoration: InputDecoration(labelText: 'Prénom')),
                  TextField(controller: _lastNameController, decoration: InputDecoration(labelText: 'Nom')),
                  TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
                  TextField(controller: _quotaController, decoration: InputDecoration(labelText: 'Cotisation annuelle cible (€/DH)'), keyboardType: TextInputType.number),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(labelText: 'Rôle'),
                    items: Constants.userRoles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                    onChanged: (val) {
                      if (val != null) _selectedRole = val;
                    },
                  ),
                  if (_isLoading) Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.primary)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: _isLoading ? null : () => Navigator.pop(ctx), child: Text('Annuler')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: _isLoading ? null : () async {
                  if (_emailController.text.isEmpty || _firstNameController.text.isEmpty) return;
                  
                  setStateDialog(() => _isLoading = true);
                  try {
                    String password = _generateRandomPassword();
                    String cleanEmail = _emailController.text.trim();
                    
                    await _firestore.collection('users').doc(cleanEmail.toLowerCase().replaceAll('.', '_')).set({
                      'email': cleanEmail,
                      'firstName': _firstNameController.text.trim(),
                      'lastName': _lastNameController.text.trim(),
                      'role': _selectedRole,
                      'annualQuota': double.tryParse(_quotaController.text) ?? 0.0,
                      'createdAt': FieldValue.serverTimestamp(),
                      'isInvited': true,
                      'tempPassword': password
                    });

                    await AuditService.logAction('Ajout Membre', 'Le membre ${_firstNameController.text} ${_lastNameController.text} a été ajouté.');
                    
                    await _sendEmailJS(cleanEmail, password, _firstNameController.text.trim());
                    
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invitation envoyée avec succès à ${_emailController.text} !'), backgroundColor: Colors.green),
                    );
                  } catch (e) {
                    setStateDialog(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
                  }
                },
                child: Text('Créer Accès & Envoyer Email'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _editUser(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final _firstNameController = TextEditingController(text: data['firstName']);
    final _lastNameController = TextEditingController(text: data['lastName']);
    final _emailController = TextEditingController(text: data['email']);
    final _quotaController = TextEditingController(text: (data['annualQuota'] ?? 0.0).toString());
    String _selectedRole = data['role'] ?? 'Membre';
    if (!Constants.userRoles.contains(_selectedRole)) _selectedRole = 'Membre';
    bool _isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Modifier Membre'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: _firstNameController, decoration: InputDecoration(labelText: 'Prénom')),
                  TextField(controller: _lastNameController, decoration: InputDecoration(labelText: 'Nom')),
                  TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
                  TextField(controller: _quotaController, decoration: InputDecoration(labelText: 'Cotisation annuelle cible (€/DH)'), keyboardType: TextInputType.number),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(labelText: 'Rôle'),
                    items: Constants.userRoles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                    onChanged: (val) {
                      if (val != null) _selectedRole = val;
                    },
                  ),
                  if (_isLoading) Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.primary)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: _isLoading ? null : () => Navigator.pop(ctx), child: Text('Annuler')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: _isLoading ? null : () async {
                  if (_emailController.text.isEmpty || _firstNameController.text.isEmpty) return;
                  
                  setStateDialog(() => _isLoading = true);
                  try {
                    await _firestore.collection('users').doc(doc.id).update({
                      'email': _emailController.text.trim(),
                      'firstName': _firstNameController.text.trim(),
                      'lastName': _lastNameController.text.trim(),
                      'role': _selectedRole,
                      'annualQuota': double.tryParse(_quotaController.text) ?? 0.0,
                    });

                    await AuditService.logAction('Modification Membre', 'Les informations de ${_firstNameController.text} ${_lastNameController.text} ont été mises à jour.');

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Membre modifié avec succès !'), backgroundColor: Colors.green),
                    );
                  } catch (e) {
                    setStateDialog(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
                  }
                },
                child: Text('Enregistrer'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _resetDatabase() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('DANGER : Remise à Zéro', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('Voulez-vous vraiment effacer TOUTES les transactions, notes de frais et l\'historique ?\n\n(Vos membres et accès utilisateurs seront conservés, mais le "Montant Payé" de chaque membre sera remis à 0).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Effacement en cours... Veuillez patienter.')));
              try {
                final txs = await _firestore.collection('transactions').get();
                for (var doc in txs.docs) await doc.reference.delete();
                
                final logs = await _firestore.collection('audit_logs').get();
                for (var doc in logs.docs) await doc.reference.delete();
                
                final members = await _firestore.collection('members').get();
                for (var doc in members.docs) await doc.reference.update({'amountPaid': 0.0});

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Base de données remise à zéro ! (Rechargez la page pour voir les changements)'), backgroundColor: Colors.green));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
              }
            },
            child: Text('OUI, TOUT EFFACER'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Administration'),
          backgroundColor: AppColors.secondary,
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Utilisateurs'),
              Tab(icon: Icon(Icons.category), text: 'Catégories'),
              Tab(icon: Icon(Icons.calendar_today), text: 'Exercice'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUsersTab(),
            _buildCategoriesTab(),
            _buildExerciceTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text('Aucun utilisateur trouvé.'));

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final doc = users[index];
              final data = doc.data() as Map<String, dynamic>;
              final role = data['role'] ?? 'Membre';
              
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Icon(Icons.person), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  title: Text('${data['firstName']} ${data['lastName']}', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${data['email']}\nRôle actuel: $role'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButton<String>(
                        value: Constants.userRoles.contains(role) ? role : 'Membre',
                        items: Constants.userRoles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                        onChanged: (newRole) async {
                          if (newRole != null) {
                            await _firestore.collection('users').doc(doc.id).update({'role': newRole});
                            await AuditService.logAction('Changement de Rôle', 'Le rôle de ${data['firstName']} a été changé en $newRole.');
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rôle mis à jour !')));
                          }
                        },
                      ),
                      IconButton(icon: Icon(Icons.edit, color: Colors.blue), onPressed: () => _editUser(doc)),
                      if (_auth.currentUser?.uid != doc.id && _auth.currentUser?.email != data['email'])
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('Supprimer cet utilisateur ?'),
                                content: Text("Êtes-vous sûr de vouloir révoquer l'accès de ${data['firstName']} ?"),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                    onPressed: () async {
                                      Navigator.pop(ctx);
                                      await _firestore.collection('users').doc(doc.id).delete();
                                      await AuditService.logAction('Suppression Membre', 'Le membre ${data['firstName']} ${data['lastName']} a été supprimé.');
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Utilisateur supprimé.')));
                                    },
                                    child: Text('Supprimer'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addUser,
        label: Text('Ajouter Utilisateur'),
        icon: Icon(Icons.add),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return Consumer<CategoryProvider>(
      builder: (context, provider, child) {
        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildCategorySection('Recettes (Entrées)', 'income', provider.incomeCategories, provider),
            SizedBox(height: 24),
            _buildCategorySection('Dépenses (Sorties)', 'expense', provider.expenseCategories, provider),
          ],
        );
      },
    );
  }

  Widget _buildCategorySection(String title, String type, List<String> categories, CategoryProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                IconButton(
                  icon: Icon(Icons.add_circle, color: AppColors.primary),
                  onPressed: () => _showAddCategoryDialog(context, type, provider),
                )
              ],
            ),
            Divider(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) => Chip(
                label: Text(cat),
                onDeleted: () => _confirmDeleteCategory(context, type, cat, provider),
                deleteIconColor: Colors.red,
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, String type, CategoryProvider provider) {
    final _ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ajouter Catégorie'),
        content: TextField(controller: _ctrl, decoration: InputDecoration(hintText: 'Nom de la catégorie')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              provider.addCategory(type, _ctrl.text);
              Navigator.pop(ctx);
            },
            child: Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, String type, String cat, CategoryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer la catégorie ?'),
        content: Text('Voulez-vous vraiment supprimer "$cat" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              provider.removeCategory(type, cat);
              Navigator.pop(ctx);
            },
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciceTab() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.autorenew, color: Colors.blue[800], size: 30),
                    SizedBox(width: 10),
                    Expanded(child: Text('Nouvelle Année de Cotisation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900]))),
                  ],
                ),
                SizedBox(height: 10),
                Text('Cette action permet de définir une nouvelle cible de cotisation pour tous les membres. Les montants payés seront remis à zéro, et les dettes de l\'année en cours seront reportées (additionnées à la nouvelle cible).', style: TextStyle(color: Colors.blue[800])),
                SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white),
                    icon: Icon(Icons.play_arrow),
                    label: Text('Lancer une Nouvelle Année'),
                    onPressed: () => _showNewYearDialog(),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        Card(
          color: Colors.orange[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.archive, color: Colors.orange[800], size: 30),
                    SizedBox(width: 10),
                    Expanded(child: Text('Clôturer un Exercice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[900]))),
                  ],
                ),
                SizedBox(height: 10),
                Text('Archive toutes les transactions d\'une année donnée. Elles disparaîtront du registre principal pour ne s\'afficher que dans l\'onglet "Archives", allégeant ainsi la vue principale.', style: TextStyle(color: Colors.orange[800])),
                SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700], foregroundColor: Colors.white),
                    icon: Icon(Icons.lock),
                    label: Text('Clôturer et Archiver'),
                    onPressed: () => _showArchiveDialog(),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 32),
        Divider(),
        ListTile(
          leading: Icon(Icons.delete_forever, color: Colors.red),
          title: Text('Zone de Danger', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          subtitle: Text('Remise à zéro totale de la base de données'),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: _resetDatabase,
            child: Text('EFFACER'),
          ),
        ),
      ],
    );
  }

  void _showNewYearDialog() {
    final _amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Nouvelle Année'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Définissez le montant de cotisation pour la nouvelle année. (ex: 1200)'),
            SizedBox(height: 16),
            TextField(controller: _amountCtrl, decoration: InputDecoration(labelText: 'Cotisation Cible (MAD)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white),
            onPressed: () async {
              final amount = double.tryParse(_amountCtrl.text);
              if (amount != null && amount > 0) {
                Navigator.pop(ctx);
                await Provider.of<MemberProvider>(context, listen: false).newYearReset(amount);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nouvelle année appliquée avec succès !')));
              }
            },
            child: Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showArchiveDialog() {
    final _yearCtrl = TextEditingController(text: DateTime.now().year.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Archiver un exercice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Quelle année voulez-vous clôturer et archiver ?'),
            SizedBox(height: 16),
            TextField(controller: _yearCtrl, decoration: InputDecoration(labelText: 'Année (ex: 2024)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700], foregroundColor: Colors.white),
            onPressed: () async {
              final year = int.tryParse(_yearCtrl.text);
              if (year != null && year > 2000) {
                Navigator.pop(ctx);
                await Provider.of<TransactionProvider>(context, listen: false).archiveExercice(year);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exercice $year archivé avec succès !')));
              }
            },
            child: Text('Archiver'),
          ),
        ],
      ),
    );
  }
}
