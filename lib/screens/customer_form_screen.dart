import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/customer.dart';
import '../repositories/repositories.dart';
import '../widgets/form_scaffold.dart';
import '../widgets/reusable_form.dart';
import '../widgets/validators.dart';

class CustomerFormScreen extends StatefulWidget {
  final int? id;
  const CustomerFormScreen({super.key, this.id});
  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final form = GlobalKey<FormState>();
  late final CustomerRepository repo;
  final name = TextEditingController(),
      email = TextEditingController(),
      phone = TextEditingController(),
      cardNumber = TextEditingController(),
      points = TextEditingController();
  String level = 'Bronze';
  bool dirty = false, saving = false;
  String? duplicate;
  @override
  void initState() {
    super.initState();
    repo = context.read<CustomerRepository>();
    _load();
  }

  Future<void> _load() async {
    if (widget.id != null) {
      final e = await repo.findById(widget.id!);
      if (e != null) {
        name.text = e.name;
        email.text = e.email;
        phone.text = e.phone;
        cardNumber.text = e.card.number;
        points.text = '${e.card.bonusPoints}';
        level = e.card.level;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    setState(() => duplicate = null);
    if (!form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      if (await repo.existsBy('email', email.text.trim(),
          exceptId: widget.id)) {
        setState(() => duplicate = 'Клиент с таким email уже существует');
        return;
      }
      final e = Customer(
          id: widget.id ?? 0,
          name: name.text.trim(),
          email: email.text.trim(),
          phone: phone.text.trim(),
          card: LoyaltyCard(
              number: cardNumber.text.trim(),
              level: level,
              bonusPoints: int.parse(points.text.trim())));
      if (widget.id == null) {
        await repo.create(e);
      } else {
        await repo.update(e);
      }
      if (mounted) {
        dirty = false;
        context.go('/customers');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    cardNumber.dispose();
    points.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DirtyFormScaffold(
      title: widget.id == null ? 'Новый клиент' : 'Редактирование клиента',
      isDirty: dirty,
      child: ReusableEntityForm(
          formKey: form,
          onSave: _save,
          saveText: saving ? 'Сохранение...' : 'Сохранить',
          fields: [
            TextFormField(
                controller: name,
                validator: (v) => textLength(v, label: 'Имя', min: 2, max: 100),
                onChanged: (_) => setState(() => dirty = true),
                decoration: const InputDecoration(labelText: 'Имя')),
            const SizedBox(height: 14),
            TextFormField(
                controller: email,
                validator: (v) => duplicate ?? emailValidator(v),
                onChanged: (_) => setState(() => dirty = true),
                decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 14),
            TextFormField(
                controller: phone,
                validator: phoneValidator,
                onChanged: (_) => setState(() => dirty = true),
                decoration: const InputDecoration(labelText: 'Телефон')),
            const Divider(height: 32),
            const Text('Карта лояльности',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            TextFormField(
                controller: cardNumber,
                validator: (v) =>
                    textLength(v, label: 'Номер карты', min: 4, max: 30),
                onChanged: (_) => setState(() => dirty = true),
                decoration: const InputDecoration(labelText: 'Номер карты')),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
                initialValue: level,
                decoration: const InputDecoration(labelText: 'Уровень'),
                items: const [
                  DropdownMenuItem(value: 'Bronze', child: Text('Bronze')),
                  DropdownMenuItem(value: 'Silver', child: Text('Silver')),
                  DropdownMenuItem(value: 'Gold', child: Text('Gold'))
                ],
                onChanged: (v) => setState(() {
                      level = v ?? 'Bronze';
                      dirty = true;
                    })),
            const SizedBox(height: 14),
            TextFormField(
                controller: points,
                keyboardType: TextInputType.number,
                validator: (v) => nonNegativeInt(v, label: 'Бонусные баллы'),
                onChanged: (_) => setState(() => dirty = true),
                decoration: const InputDecoration(labelText: 'Бонусные баллы')),
            if (widget.id != null)
              Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: OutlinedButton.icon(
                      onPressed: () async {
                        final router = GoRouter.of(context);
                        await repo.softDelete(widget.id!);
                        if (!mounted) return;
                        router.go('/customers');
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Логически удалить')))
          ]));
}
