import 'package:get_it/get_it.dart';
import 'package:libre_translate/libre_translate.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:translation_bot/errors.dart';

final detect = ChatCommand(
  'detect',
  'Detect the language of some text',
  id('detect', (
    ChatContext context, [
    @Description('The text to run detection on') String? text,
  ]) async {
    if (context is MessageChatContext) {
      text = context.rawArguments.trim();
    } else if (text == null && context is InteractionChatContext) {
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

    final languages = (await libreTranslate.detect(text)).entries.toList()
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
  }),
);
