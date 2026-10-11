import 'package:flutter/material.dart';

class FormFieldSpec {
  final String label;
  final Widget Function(FormFieldState<dynamic>) builder;
  const FormFieldSpec({required this.label, required this.builder});
}

class ReusableEntityForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<Widget> fields;
  final VoidCallback onSave;
  final String saveText;
  const ReusableEntityForm(
      {super.key,
      required this.formKey,
      required this.fields,
      required this.onSave,
      this.saveText = 'Сохранить'});
  @override
  Widget build(BuildContext context) => Form(
      key: formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ...fields,
        const SizedBox(height: 20),
        FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save),
            label: Text(saveText))
      ]));
}
