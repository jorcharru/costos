import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:costos/main.dart'; // Cambia 'costos_app' por el nombre de tu proyecto.

void main() {
  testWidgets('Verificar que la pantalla inicial se renderiza correctamente', (WidgetTester tester) async {
    // Construye la aplicación y renderiza un frame.
    await tester.pumpWidget(MyApp()); // Sin const

    // Verifica que el título de la aplicación esté presente.
    expect(find.text('COSTOS'), findsOneWidget);

    // Verifica que el nombre "Jorge Charrupi" esté presente.
    expect(find.text('Jorge Charrupi'), findsOneWidget);

    // Verifica que los campos de entrada estén presentes.
    expect(find.byType(TextField), findsWidgets);

    // Verifica que los botones estén presentes.
    expect(find.text('Agregar Fila'), findsOneWidget);
    expect(find.text('Quitar Fila'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
    expect(find.text('Registro'), findsOneWidget);
  });
}