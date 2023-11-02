import 'package:get_it/get_it.dart';
import 'package:libre_translate/libre_translate.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

final languageConverter = SimpleConverter<Language>(
  provider: (context) => GetIt.I.get<List<Language>>(),
  stringify: (l) => l.name,
);
