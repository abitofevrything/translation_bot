import 'package:get_it/get_it.dart';
import 'package:libre_translate/libre_translate.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';
import 'package:translation_bot/errors.dart';

final translate = ChatCommand(
  'translate',
  'Translate text from one language to another',
  id('translate', (
    ChatContext context,
    @Description('The language to translate to') Language to, [
    @Description('The language to translate from') Language? from,
    @Description('The text to translate') String? text,
  ]) async {
    if (text == null && context is InteractionChatContext) {
      final modal = await context.getModal(
        title: 'Detect language',
        components: [
          TextInputBuilder(
            customId: 'text',
            style: TextInputStyle.paragraph,
            label: 'Enter the text to detect the language of',
          )
        ],
      );

      text = modal['text']!.trim();
    }

    if (text == null || text.isEmpty) {
      throw InputRequiredException();
    }

    final libreTranslate = GetIt.I.get<LibreTranslateClient>();
    final availableLanguages = GetIt.I.get<List<Language>>();

    if (from == null) {
      final detected = (await libreTranslate.detect(text)).entries.fold<MapEntry<String, double>?>(
          null,
          (previousValue, element) => previousValue == null || element.value > previousValue.value
              ? element
              : previousValue);

      if (detected != null && detected.value > 0.5) {
        from = availableLanguages.singleWhere((element) => element.code == detected.key);
      } else {
        from = await context.getSelection(
          availableLanguages.where((element) => element.targets.contains(to.code)).toList(),
          MessageBuilder(embeds: [
            EmbedBuilder(
              title: 'Unable to detect language',
              color: DiscordColor.fromRgb(255, 0, 0),
              description: 'Unable to detect the language of the input. Please select it below.',
            ),
          ]),
        );
      }
    }

    final translated = await libreTranslate.translate(text, source: from!.code, target: to.code);

    await context.respond(await pagination.splitEmbeds(
      translated,
      buildChunk: (chunk) => EmbedBuilder(
        title: 'Translated text',
        color: DiscordColor.fromRgb(0, 162, 255),
        description: chunk,
      ),
      userId: context.user.id,
    ));
  }),
);
