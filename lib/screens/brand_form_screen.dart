import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/brand.dart';
import '../repositories/repositories.dart';
import '../widgets/form_scaffold.dart';
import '../widgets/reusable_form.dart';
import '../widgets/validators.dart';

class BrandFormScreen extends StatefulWidget {
  final int? id;

  const BrandFormScreen({super.key, this.id});

  @override
  State<BrandFormScreen> createState() => _BrandFormScreenState();
}

class _BrandFormScreenState extends State<BrandFormScreen> {
  final keyForm = GlobalKey<FormState>();
  late final BrandRepository repo;
  final name = TextEditingController();
  final country = TextEditingController();
  final description = TextEditingController();

  bool dirty = false, saving = false;
  String? duplicate;

  @override
  void initState() {
    super.initState();
    repo = context.read<BrandRepository>();
    _load();
  }

  Future<void> _load() async {
    if (widget.id != null) {
      final e = await repo.findById(widget.id!);
      if (e != null) {
        name.text = e.name;
        country.text = e.country;
        description.text = e.description;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    setState(() => duplicate = null);
    if (!keyForm.currentState!.validate()) return;
    setState(() => saving = true);

    try {
      if (await repo.existsBy(
        'name',
        name.text.trim(),
        exceptId: widget.id,
      )) {
        if (!mounted) return;
        setState(() => duplicate = 'Бренд с таким названием уже существует');
        return;
      }

      final item = Brand(
        id: widget.id ?? 0,
        name: name.text.trim(),
        country: country.text.trim(),
        description: description.text.trim(),
      );

      if (widget.id == null) {
        await repo.create(item);
      } else {
        await repo.update(item);
      }

      if (!mounted) return;
      dirty = false;
      context.go('/brands');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    country.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DirtyFormScaffold(
        title: widget.id == null ? 'Новый бренд' : 'Редактирование бренда',
        isDirty: dirty,
        child: ReusableEntityForm(
          formKey: keyForm,
          saveText: saving ? 'Сохранение...' : 'Сохранить',
          onSave: _save,
          fields: [
            TextFormField(
              controller: name,
              validator: (v) =>
                  duplicate ??
                  textLength(v, label: 'Название', min: 2, max: 80),
              onChanged: (_) => setState(() => dirty = true),
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: country,
              validator: (v) => textLength(v, label: 'Страна', min: 2, max: 60),
              onChanged: (_) => setState(() => dirty = true),
              decoration: const InputDecoration(labelText: 'Страна'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: description,
              maxLines: 4,
              validator: (v) =>
                  textLength(v, label: 'Описание', min: 10, max: 300),
              onChanged: (_) => setState(() => dirty = true),
              decoration: const InputDecoration(labelText: 'Описание'),
            ),
            if (widget.id != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final router = GoRouter.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await repo.hardDelete(widget.id!);
                      if (!mounted) return;
                      router.go('/brands');
                    } catch (e) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Физически удалить'),
                ),
              ),
          ],
        ),
      );
}
