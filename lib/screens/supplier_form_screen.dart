import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../widgets/form_scaffold.dart';
import '../widgets/reusable_form.dart';
import '../widgets/validators.dart';

class SupplierFormScreen extends StatefulWidget {
  final int? id;
  const SupplierFormScreen({super.key, this.id});
  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final form = GlobalKey<FormState>();
  late final SupplierRepository repo;
  late final BrandRepository brands;
  final name = TextEditingController(),
      email = TextEditingController(),
      phone = TextEditingController(),
      description = TextEditingController();
  int? brandId;
  bool dirty = false, saving = false;
  Future<PageResult<Brand>>? brandFuture;
  @override
  void initState() {
    super.initState();
    repo = context.read<SupplierRepository>();
    brands = context.read<BrandRepository>();
    brandFuture = context.read<ReferenceCache>().getBrands();
    _load();
  }

  Future<void> _load() async {
    if (widget.id != null) {
      final e = await repo.findById(widget.id!);
      if (e != null) {
        name.text = e.name;
        email.text = e.email;
        phone.text = e.phone;
        description.text = e.description;
        brandId = e.brandId;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    if (!form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final e = Supplier(
          id: widget.id ?? 0,
          name: name.text.trim(),
          brandId: brandId!,
          email: email.text.trim(),
          phone: phone.text.trim(),
          description: description.text.trim());
      if (widget.id == null) {
        await repo.create(e);
      } else {
        await repo.update(e);
      }
      if (mounted) {
        dirty = false;
        context.go('/suppliers');
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
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DirtyFormScaffold(
      title:
          widget.id == null ? 'Новый поставщик' : 'Редактирование поставщика',
      isDirty: dirty,
      child: ReusableEntityForm(
          formKey: form,
          onSave: _save,
          saveText: saving ? 'Сохранение...' : 'Сохранить',
          fields: [
            TextFormField(
                controller: name,
                validator: (v) =>
                    textLength(v, label: 'Название', min: 2, max: 100),
                onChanged: (_) => setState(() => dirty = true),
                decoration: const InputDecoration(labelText: 'Название')),
            const SizedBox(height: 14),
            FutureBuilder<PageResult<Brand>>(
                future: brandFuture,
                builder: (context, s) {
                  final items = s.data?.items ?? const <Brand>[];
                  return DropdownButtonFormField<int>(
                      initialValue:
                          items.any((e) => e.id == brandId) ? brandId : null,
                      decoration: const InputDecoration(labelText: 'Бренд'),
                      items: items
                          .map((e) => DropdownMenuItem(
                              value: e.id, child: Text(e.name)))
                          .toList(),
                      onChanged: (v) => setState(() {
                            brandId = v;
                            dirty = true;
                          }),
                      validator: (v) => v == null ? 'Выберите бренд' : null);
                }),
            const SizedBox(height: 14),
            TextFormField(
                controller: email,
                validator: emailValidator,
                onChanged: (_) => setState(() => dirty = true),
                decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 14),
            TextFormField(
                controller: phone,
                validator: phoneValidator,
                onChanged: (_) => setState(() => dirty = true),
                decoration: const InputDecoration(labelText: 'Телефон')),
            const SizedBox(height: 14),
            TextFormField(
                controller: description,
                maxLines: 4,
                validator: (v) =>
                    textLength(v, label: 'Описание', min: 10, max: 300),
                onChanged: (_) => setState(() => dirty = true),
                decoration: const InputDecoration(labelText: 'Описание')),
            if (widget.id != null)
              Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: OutlinedButton.icon(
                      onPressed: () async {
                        final router = GoRouter.of(context);
                        await repo.softDelete(widget.id!);
                        if (!mounted) return;
                        router.go('/suppliers');
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Логически удалить')))
          ]));
}
