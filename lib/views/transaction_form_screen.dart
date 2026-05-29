import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/member_provider.dart';
import '../providers/category_provider.dart';
import '../utils/app_colors.dart';

class TransactionFormScreen extends StatefulWidget {
  @override
  _TransactionFormScreenState createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _type = 'expense';
  String? _category;
  File? _imageFile;
  String? _selectedMemberId;
  String? _selectedMemberName;
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;

    final t = TransactionModel(
      id: '',
      date: _selectedDate,
      amount: amount,
      type: _type,
      category: _category ?? '',
      notes: _notesController.text,
      memberId: _selectedMemberId,
      memberName: _selectedMemberName,
    );

    await Provider.of<TransactionProvider>(context, listen: false)
        .addTransaction(t, imageFile: _imageFile);

    if (_type == 'income' && _selectedMemberId != null) {
      Provider.of<MemberProvider>(context, listen: false).addPayment(_selectedMemberId!, amount);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaction ajoutée avec succès !'), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nouvelle Transaction'), backgroundColor: AppColors.secondary),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Consumer<MemberProvider>(
            builder: (context, memberProvider, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Type
                  DropdownButtonFormField<String>(
                    value: _type,
                    items: [
                      DropdownMenuItem(value: 'income', child: Text('✅ Recette (Entrée)')),
                      DropdownMenuItem(value: 'expense', child: Text('❌ Dépense (Sortie)')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _type = val!;
                        _category = null;
                        _selectedMemberId = null;
                        _selectedMemberName = null;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Catégorie
                  // Catégorie — charger depuis CategoryProvider
                  Consumer<CategoryProvider>(
                    builder: (context, catProvider, _) {
                      final cats = _type == 'income' ? catProvider.incomeCategories : catProvider.expenseCategories;
                      if (_category == null || !cats.contains(_category)) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (cats.isNotEmpty) setState(() => _category = cats.first);
                        });
                      }
                      return DropdownButtonFormField<String>(
                        value: _category != null && cats.contains(_category) ? _category : (cats.isNotEmpty ? cats.first : null),
                        items: cats.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                        onChanged: (val) => setState(() => _category = val!),
                        decoration: InputDecoration(
                          labelText: 'Catégorie',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 16),

                  // Membre
                  DropdownButtonFormField<String?>(
                    value: _selectedMemberId,
                    items: [
                      DropdownMenuItem<String?>(value: null, child: Text('Aucun (Optionnel)')),
                      ...memberProvider.members
                          .map((m) => DropdownMenuItem(value: m.id, child: Text('${m.firstName} ${m.lastName}')))
                          .toList(),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedMemberId = val;
                        if (val != null) {
                          final m = memberProvider.members.firstWhere((m) => m.id == val);
                          _selectedMemberName = '${m.firstName} ${m.lastName}';
                        } else {
                          _selectedMemberName = null;
                        }
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Membre Associé',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Montant
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Montant (MAD)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Veuillez entrer un montant.';
                      final n = double.tryParse(val);
                      if (n == null || n <= 0) return 'Montant invalide (doit être supérieur à 0).';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Date
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date de la transaction',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: Icon(Icons.calendar_today),
                        suffixIcon: Icon(Icons.edit_calendar, color: AppColors.primary),
                      ),
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(_selectedDate),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes (optionnel)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(height: 16),

                  // Pièce jointe
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: Icon(Icons.camera_alt),
                          label: Text('Photo'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.secondary),
                            foregroundColor: AppColors.secondary,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: Icon(Icons.image),
                          label: Text('Galerie'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.secondary),
                            foregroundColor: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_imageFile != null) ...[
                    SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_imageFile!, height: 120, fit: BoxFit.cover),
                    ),
                  ],
                  SizedBox(height: 32),

                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: Icon(Icons.save),
                    label: Text('Enregistrer la Transaction'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
