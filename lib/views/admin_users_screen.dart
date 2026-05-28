import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';

class AdminUsersScreen extends StatefulWidget {
  @override
  _AdminUsersScreenState createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<UserModel> users = [
    UserModel(id: 'U1', firstName: 'Admin', lastName: 'Principal', email: 'admin@taweda.com', role: 'Admin'),
    UserModel(id: 'U2', firstName: 'Trésorier', lastName: 'Local', email: 'tresorier@taweda.com', role: 'Trésorier'),
    UserModel(id: 'U3', firstName: 'Invité', lastName: 'Obs', email: 'observateur@taweda.com', role: 'Observateur'),
  ];

  void _addUser() {
    final _firstNameController = TextEditingController();
    final _lastNameController = TextEditingController();
    final _emailController = TextEditingController();
    String _selectedRole = 'Membre';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ajouter Utilisateur / Accès'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _firstNameController, decoration: InputDecoration(labelText: 'Prénom')),
              TextField(controller: _lastNameController, decoration: InputDecoration(labelText: 'Nom')),
              TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(labelText: 'Rôle'),
                items: Constants.userRoles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                onChanged: (val) {
                  if (val != null) _selectedRole = val;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                users.add(UserModel(
                  id: 'U${users.length + 1}',
                  firstName: _firstNameController.text,
                  lastName: _lastNameController.text,
                  email: _emailController.text,
                  role: _selectedRole,
                ));
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Un email a été envoyé à ${_emailController.text} pour avoir accès à l\'application et créer un mot de passe.'), backgroundColor: Colors.green),
              );
            },
            child: Text('Créer Accès'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des Utilisateurs'),
        backgroundColor: AppColors.secondary,
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(child: Icon(Icons.person), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              title: Text('${user.firstName} ${user.lastName}', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${user.email}\nRôle actuel: ${user.role}'),
              trailing: DropdownButton<String>(
                value: user.role,
                items: Constants.userRoles.map((role) {
                  return DropdownMenuItem(value: role, child: Text(role));
                }).toList(),
                onChanged: (newRole) {
                  if (newRole != null) {
                    setState(() {
                      users[index] = UserModel(
                        id: user.id,
                        firstName: user.firstName,
                        lastName: user.lastName,
                        email: user.email,
                        role: newRole,
                      );
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rôle mis à jour pour ${user.firstName} !')));
                  }
                },
              ),
            ),
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
}
