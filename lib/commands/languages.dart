import 'package:get_it/get_it.dart';
import 'package:libre_translate/libre_translate.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';

final languages = ChatCommand(
  'languages',
  'See which languages the bot can speak',
  id('languages', (ChatContext context) async {
    final availableLanguages = GetIt.I.get<List<Language>>();

    await context.respond(await pagination.builders(
      userId: context.user.id,
      [
        for (final language in availableLanguages)
          MessageBuilder(embeds: [
            EmbedBuilder(
              title: '${language.name} (${language.code})',
              color: DiscordColor.fromRgb(0, 162, 255),
              fields: [
                EmbedFieldBuilder(
                  name: 'Translation targets',
                  value: language.targets
                      .map((e) => availableLanguages.singleWhere((element) => element.code == e))
                      .map((e) => e.name)
                      .join(', '),
                  isInline: false,
                ),
              ],
            ),
          ])
      ],
    ));
  }),
);
