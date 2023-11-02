import 'package:get_it/get_it.dart';
import 'package:libre_translate/libre_translate.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

final messageDetect = MessageCommand(
  'Detect Language',
  (context) async {
    if (context.targetMessage.content.trim().isEmpty) {
      await context.respond(
        level: ResponseLevel.hint,
        MessageBuilder(embeds: [
          EmbedBuilder(
            title: 'Invalid input',
            color: DiscordColor.fromRgb(255, 0, 0),
            description:
                "I couldn't find any text in that message. This command only works on messages where the text is sent as a normal message.",
          ),
        ]),
      );
      return;
    }

    final libreTranslate = GetIt.I.get<LibreTranslateClient>();
    final availableLanguages = GetIt.I.get<List<Language>>();

    final languages = (await libreTranslate.detect(context.targetMessage.content)).entries.toList()
      ..sort((a, b) => -a.value.compareTo(b.value));

    if (languages.isEmpty) {
      await context.respond(
        level: ResponseLevel.hint,
        MessageBuilder(embeds: [
          EmbedBuilder(
            title: 'No language detected',
            color: DiscordColor.fromRgb(255, 0, 0),
            description: 'No language was detected for your input.',
          ),
        ]),
      );
    } else {
      final top = availableLanguages.singleWhere((element) => element.code == languages.first.key);

      await context.respond(MessageBuilder(embeds: [
        EmbedBuilder(
          title: 'Detected language: ${top.name}!',
          color: DiscordColor.fromRgb(0, 162, 255),
          description:
              'Yout text appears to be ${top.name} (${languages.first.value.toStringAsFixed(2)}% confidence).',
          footer: EmbedFooterBuilder(
            text:
                'Top 5: ${languages.take(5).map((e) => '${e.key} (${e.value.toStringAsFixed(2)}%)').join(', ')}',
          ),
        ),
      ]));
    }
  },
);
