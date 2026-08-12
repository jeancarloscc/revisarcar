import 'package:flutter/material.dart';

Future<bool> confirmarExclusaoDialog(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String textoConfirmar = 'Excluir',
}) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(textoConfirmar),
        ),
      ],
    ),
  );
  return confirmar ?? false;
}
