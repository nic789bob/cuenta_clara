import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cuenta_clara/data/pagos_demostracion.dart';
import 'package:cuenta_clara/main.dart';
import 'package:cuenta_clara/models/pago.dart';
import 'package:cuenta_clara/utils/formato.dart';

void main() {
  test('copyWith cambia estado y conserva el mismo identificador', () {
    final original = Pago(
      id: 'abc',
      concepto: 'Internet',
      responsable: 'Mamá',
      categoria: CategoriaPago.servicios,
      monto: 110000,
      fechaVencimiento: DateTime(2026, 10, 22),
      pagado: false,
      nota: '',
    );

    final nuevo = original.copyWith(pagado: true);

    expect(nuevo.id, 'abc');
    expect(nuevo.pagado, true);
    expect(nuevo.responsable, 'Mamá');
    expect(original.pagado, false); // Inmutabilidad.
  });

  test('copyWith permite actualizar el responsable del pago', () {
    final original = Pago(
      id: 'def',
      concepto: 'Arriendo',
      responsable: 'Papá',
      categoria: CategoriaPago.vivienda,
      monto: 950000,
      fechaVencimiento: DateTime(2026, 11, 5),
      pagado: false,
      nota: 'Mensual',
    );

    final actualizado = original.copyWith(responsable: 'Mamá');

    expect(actualizado.id, 'def');
    expect(actualizado.responsable, 'Mamá');
    expect(original.responsable, 'Papá');
  });

  test('crearPagosDemostracion incluye responsable en todos los registros', () {
    final pagos = crearPagosDemostracion();

    expect(pagos.length, 3);
    for (final pago in pagos) {
      expect(pago.responsable.trim().isNotEmpty, true);
    }
  });

  test('formatearPesos utiliza separadores de miles', () {
    expect(formatearPesos(1250000), '\$1.250.000');
    expect(formatearPesos(0), '\$0');
  });

  testWidgets(
    'Flujo CRUD completo (P01 a P07): crear, validar, editar, estado y eliminar',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const CuentaClaraApp());

      // Verificar totales iniciales: $1.060.000 por pagar, $85.000 pagado, 1 vencido
      expect(find.text('\$1.060.000'), findsOneWidget);
      expect(find.text('\$85.000'), findsNWidgets(2));
      expect(find.text('Internet del hogar'), findsOneWidget);
      expect(find.text('Responsable: Mamá'), findsOneWidget);

      // Abrir formulario de Nuevo pago
      await tester.tap(find.text('Nuevo pago'));
      await tester.pumpAndSettle();

      // P02: Registrar sin concepto ni responsable
      await tester.tap(find.text('Registrar pago'));
      await tester.pump();
      expect(find.text('Escriba el concepto del pago'), findsOneWidget);
      expect(find.text('Escriba el responsable del pago'), findsOneWidget);

      // P03: Registrar con monto igual a 0
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Concepto'),
        'Factura de energía',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Responsable del pago'),
        'Yo',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Monto en COP'),
        '0',
      );
      await tester.tap(find.text('Registrar pago'));
      await tester.pump();
      expect(find.text('Ingrese un monto mayor que cero'), findsOneWidget);

      // P01: Crear un pago de $150.000, pendiente
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Monto en COP'),
        '150000',
      );
      await tester.tap(find.text('Registrar pago'));
      await tester.pumpAndSettle();

      expect(find.text('Factura de energía'), findsOneWidget);
      expect(find.text('\$1.210.000'), findsOneWidget);

      // P04: Editar el monto a $165.000 sin duplicar
      await tester.tap(find.text('Factura de energía'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Monto en COP'),
        '165000',
      );
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(find.text('Factura de energía'), findsOneWidget);
      expect(find.text('\$1.225.000'), findsOneWidget);

      // P05: Marcar el nuevo pago como pagado
      final tarjetaFactura = find.ancestor(
        of: find.text('Factura de energía'),
        matching: find.byType(Card),
      );
      await tester.tap(
        find.descendant(
          of: tarjetaFactura,
          matching: find.byIcon(Icons.more_vert),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marcar pagado'));
      await tester.pumpAndSettle();

      expect(find.text('\$1.060.000'), findsOneWidget);
      expect(find.text('\$250.000'), findsOneWidget);

      // P06: Cancelar la eliminación
      await tester.tap(
        find.descendant(
          of: tarjetaFactura,
          matching: find.byIcon(Icons.more_vert),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Factura de energía'), findsOneWidget);

      // P07: Confirmar la eliminación
      await tester.tap(
        find.descendant(
          of: tarjetaFactura,
          matching: find.byIcon(Icons.more_vert),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();
      expect(find.text('Factura de energía'), findsNothing);
    },
  );
}
