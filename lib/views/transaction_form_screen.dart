import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/member_provider.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';

class TransactionFormScreen extends StatefulWidget {
  @override
  _TransactionFormScreenState createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _type = 'expense';
  String _category = Constants.expenseCategories.first;
  File? _imageFile;
  String? _selectedMemberId;
  String? _selectedMemberName;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _save() async {
    final t = TransactionModel(
      id: '',
      date: DateTime.now(),
      amount: double.tryParse(_amountController.text) ?? 0.0,
      type: _type,
      category: _category,
      notes: _notesController.text,
      memberId: _type == 'income' ? _selectedMemberId : null,
      memberName: _type == 'income' ? _selectedMemberName : null,
    );
    await Provider.of<TransactionProvider>(context, listen: false)
        .addTransaction(t, imageFile: _imageFile);
        
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cotisation/Transaction ajoutée avec succès !'), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nouvelle Transaction'), backgroundColor: AppColors.secondary),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Consumer<MemberProvider>(
          builder: (context, memberProvider, child) {
            return Column(
              children: [
            DropdownButtonFormField<String>(
              value: _type,
              items: [
                DropdownMenuItem(value: 'income', child: Text('Recette')),
                DropdownMenuItem(value: 'expense', child: Text('Dépense')),
              ],
              onChanged: (val) {
                setState(() {
                  _type = val!;
                  _category = _type == 'income' ? Constants.incomeCategories.first : Constants.expenseCategories.first;
                });
              },
              decoration: InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              items: (_type == 'income' ? Constants.incomeCategories : Constants.expenseCategories)
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (val) => setState(() => _category = val!),
              decoration: InputDecoration(labelText: 'Catégorie', border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),
            if (_type == 'income') ...[
              DropdownButtonFormField<String>(
                value: _selectedMemberId,
                items: memberProvider.members
                    .map((m) => DropdownMenuItem(value: m.id, child: Text('${m.firstName} ${m.lastName}')))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedMemberId = val;
                    final m = memberProvider.members.firstWhere((m) => m.id == val);
                    _selectedMemberName = '${m.firstName} ${m.lastName}';
                  });
                },
                decoration: InputDecoration(labelText: 'Membre', border: OutlineInputBorder()),
              ),
              SizedBox(height: 16),
            ],
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Montant (MAD)', border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: Icon(Icons.camera_alt),
                  label: Text('Photo'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: Icon(Icons.image),
                  label: Text('Galerie'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
                ),
              ],
            ),
            if (_imageFile != null) ...[
              SizedBox(height: 16),
              Image.file(_imageFile!, height: 100),
            ],
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text('Enregistrer'),
            ),
            ],
            );
          },
        ),
      ),
    );
  }
}
