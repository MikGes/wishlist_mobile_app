import 'package:uuid/uuid.dart';

final _uuid = Uuid();

String newId() => _uuid.v4();

