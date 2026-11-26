import 'package:intl/intl.dart';

final NumberFormat money = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
final DateFormat dateFmt = DateFormat('dd/MM/yyyy');