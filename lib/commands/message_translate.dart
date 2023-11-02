import 'package:get_it/get_it.dart';
import 'package:libre_translate/libre_translate.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';

final messageTranslate = MessageCommand(
  'Translate Message',
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

    final detected = (await libreTranslate.detect(context.targetMessage.content))
        .entries
        .fold<MapEntry<String, double>?>(
            null,
            (previousValue, element) => previousValue == null || element.value > previousValue.value
                ? element
                : previousValue);

    final Language from;
    if (detected != null && detected.value > 0.5) {
      from = availableLanguages.singleWhere((element) => element.code == detected.key);
    } else {
      from = await context.getSelection(
        availableLanguages,
        MessageBuilder(embeds: [
          EmbedBuilder(
            title: 'Unable to detect language',
            color: DiscordColor.fromRgb(255, 0, 0),
            description: 'Unable to detect the language of the input. Please select it below.',
          ),
        ]),
      );
    }

    final to = await context.getSelection(
      availableLanguages.where((element) => from.targets.contains(element.code)).toList(),
      MessageBuilder(embeds: [
        EmbedBuilder(
          title: 'Select target language',
          color: DiscordColor.fromRgb(0, 162, 255),
          description: 'Select the language you want to translate the message to.',
        ),
      ]),
    );

    final translated = await libreTranslate.translate(context.targetMessage.content,
        source: from.code, target: to.code);

    await context.respond(await pagination.splitEmbeds(
      translated,
      buildChunk: (chunk) => EmbedBuilder(
        title: 'Translated text',
        color: DiscordColor.fromRgb(0, 162, 255),
        description: chunk,
      ),
      userId: context.user.id,
    ));
  },
);
