# Gastos MVP

App móvil de gestión de gastos personales hecha con Flutter y Dart.

## Funciones
- Login y registro con Firebase Auth
- CRUD de gastos con SQLite (gastos, categorías y presupuestos)
- Foto del ticket con la cámara
- Alerta local al llegar al 80 % del presupuesto semanal
- Sincronización con Firestore
- Gráfica por categoría con fl_chart
- Notas cifradas con AES-GCM

## Cómo ejecutarla
1. flutter pub get
2. flutterfire configure --project=aplication-5dd5b
3. flutter run

## Limitaciones conocidas
- Solo se cifran las notas; la base local es por dispositivo.
- Las fotos de tickets no se sincronizan.