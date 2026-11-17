# CuentaClara — Taller Práctico 07

Aplicación móvil multiplataforma desarrollada con **Flutter y Dart** para el control de facturas y pagos del hogar (CRUD en memoria, formularios con validación, listas dinámicas con pestañas, indicadores financieros y flujo de trabajo con Git/GitHub).

---

## Estructura del proyecto

```text
cuenta_clara/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   └── pago.dart
│   ├── data/
│   │   └── pagos_demostracion.dart
│   ├── utils/
│   │   └── formato.dart
│   ├── widgets/
│   │   ├── tarjeta_pago.dart
│   │   └── resumen_pagos.dart
│   └── screens/
│       ├── formulario_pago_screen.dart
│       └── inicio_screen.dart
├── test/
│   └── pago_test.dart
└── pubspec.yaml
```

---

## Ejecución y pruebas

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run -d chrome
```

---

## 15B. Respuestas a las preguntas de comprensión

1. **¿Qué cambia si se reemplaza `ListView.builder` por tres tarjetas creadas manualmente?**
   La lista dejaría de ser dinámica: solo mostraría un número fijo de elementos, no reflejaría la adición o eliminación de registros en `_pagos` y perdería la construcción bajo demanda (*lazy building*) cuando hay muchos pagos.
2. **¿Por qué un pago editado no se debe agregar con `add()`?**
   Porque `add()` añade un elemento nuevo al final de la lista, lo que **duplicaría** el registro en lugar de actualizar el existente. Para editar se localiza su posición mediante `indexWhere((p) => p.id == pagoActual.id)` y se reemplaza en `_pagos[indice] = resultado`.
3. **¿Qué ocurriría si olvidamos llamar `setState()` después de agregar un registro?**
   El objeto sí se agregaría a la lista `_pagos` en memoria, pero Flutter no sabría que el estado cambió y **no reconstruiría la interfaz** (`build`), por lo que la nueva tarjeta ni los totales actualizados aparecerían en pantalla.
4. **¿Para qué se utiliza `mounted` al regresar de `Navigator.push()` o `showDialog()`?**
   Como `await` es asíncrono, el usuario o el sistema podría haber cerrado o desmontado el widget mientras esperaba la respuesta. Verificar `if (!mounted) return;` evita llamar a `setState()` o usar `BuildContext` sobre un `State` que ya no está en el árbol de widgets.
5. **¿Qué diferencia hay entre `git commit` y `git push`?**
   `git commit` guarda una instantánea de los cambios preparados en el **repositorio local** de nuestra máquina, mientras que `git push` envía esos commits locales al **repositorio remoto** (por ejemplo, en GitHub).

---

## 18. Respuestas del Caso B (Leer - READ)

- **¿Qué sucede cuando `ListView.builder` recibe un `itemCount` distinto?**
  `ListView.builder` ejecuta `itemBuilder` exactamente desde `0` hasta `itemCount - 1`. En la pestaña **Todos** recibe `_pagos.length` (3 inicialmente), en **Pendientes** recibe `pendientes.length` (2 inicialmente) y en **Pagados** recibe `pagados.length` (1 inicialmente). Si `datos.isEmpty`, muestra el mensaje `'No hay pagos en esta sección.'`.
- **Identificación de elementos clave en `inicio_screen.dart`:**
  - `where`: filtra la colección según una condición (`_pagos.where((p) => !p.pagado)` para pendientes, `_pagos.where((p) => p.pagado)` para pagados y `pendientes.where((p) => soloFecha(p.fechaVencimiento).isBefore(hoy))` para vencidos).
  - `toList`: convierte el `Iterable<Pago>` perezoso devuelto por `where()` en una `List<Pago>` concreta para pasarla a `_lista(...)`.
  - `fold`: acumula los montos enteros de cada lista partiendo de `0` (`pendientes.fold<int>(0, (total, p) => total + p.monto)`).
  - `ValueKey`: `key: ValueKey(pago.id)` asigna una clave única e inmutable basada en el `id` del pago para que Flutter identifique correctamente cada `TarjetaPago` al filtrar, editar o eliminar elementos.

---

## 18A. Matriz de pruebas diligenciada

| ID | Prueba a ejecutar | Resultado esperado | Estado (P/F) |
| :--- | :--- | :--- | :---: |
| **P01** | Crear un pago de \$150.000, pendiente. | Se agrega y sube «Por pagar» (de \$1.060.000 a \$1.210.000). | **P (Pass)** |
| **P02** | Registrar sin concepto (o sin responsable). | Se muestra mensaje de validación y no permite guardar. | **P (Pass)** |
| **P03** | Registrar con monto igual a 0. | No permite guardar y muestra `'Ingrese un monto mayor que cero'`. | **P (Pass)** |
| **P04** | Editar el monto a \$165.000. | No se duplica el pago y el total sube \$15.000 (\$1.225.000). | **P (Pass)** |
| **P05** | Marcar el nuevo pago como pagado. | Cambia a la pestaña Pagados y actualiza ambos totales. | **P (Pass)** |
| **P06** | Cancelar la eliminación. | El cuadro de diálogo se cierra y el pago permanece en la lista. | **P (Pass)** |
| **P07** | Confirmar la eliminación. | El pago desaparece de la lista y se recalculan los totales. | **P (Pass)** |
| **P08** | Ejecutar `flutter test`. | Todas las pruebas unitarias y de widgets pasan exitosamente. | **P (Pass)** |

---

## 21. Reto individual: Campo `responsable`

1. Se incorporó `final String responsable;` al modelo `Pago` (`lib/models/pago.dart`).
2. Se actualizó `copyWith` con `String? responsable` para permitir su edición inmutable.
3. Se añadió el `TextFormField` de **Responsable del pago** en `FormularioPagoScreen` con validación obligatoria de texto no vacío.
4. Se visualiza `'Responsable: ${pago.responsable}'` en `TarjetaPago` (`lib/widgets/tarjeta_pago.dart`).
5. Se actualizaron los registros de demostración (`Mamá`, `Papá`, `Yo`) y las pruebas automatizadas en `test/pago_test.dart`.
6. Se registró en la rama `feature/responsable-pago`.
