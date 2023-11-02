import 'package:get_it/get_it.dart';
import 'package:libre_translate/libre_translate.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:translation_bot/plugins/shadow_users.dart';

final shadowMe = ChatCommand(
  'shadow-me',
  'Enable or disable shadowing, with which the bot will translate every message you send in a channel.',
  id(
    'shadow-me',
    (
      ChatContext context,
      @Description('What you want to do')
      @Choices({'start': 'start', 'stop': 'stop'})
      String command,
    ) async {
      final availableLanguages = GetIt.I.get<List<Language>>();
      final shadowUsers = GetIt.I.get<ShadowUsers>();

      if (command == 'start') {
        final language = await context.getSelection(
          availableLanguages,
          MessageBuilder(embeds: [
            EmbedBuilder(
                title: 'Select language',
                color: DiscordColor.fromRgb(0, 162, 255),
                description: 'Select the language you want your messages to be translated to.'),
          ]),
        );

        shadowUsers.users[(context.user.id, context.channel.id)] = (language, DateTime.timestamp());

        await context.respond(MessageBuilder(embeds: [
          EmbedBuilder(
            title: 'Shadowing enabled',
            color: DiscordColor.fromRgb(0, 162, 255),
            description:
                'Shadowing is now enabled. Run `/shadow-me stop` in this channel to stop shadowing (or wait ${(ShadowUsers.duration.inMinutes / Duration.minutesPerHour).toStringAsFixed(1)} hours).',
          ),
        ]));
      } else {
        shadowUsers.users.remove((context.user.id, context.channel.id));

        await context.respond(MessageBuilder(embeds: [
          EmbedBuilder(
            title: 'Shadowing disabled',
            color: DiscordColor.fromRgb(0, 162, 255),
            description: 'Shadowing is now disabled.',
          ),
        ]));
      }
    },
  ),
);
