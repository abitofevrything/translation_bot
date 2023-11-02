import 'dart:io';

import 'package:libre_translate/libre_translate.dart';
import 'package:nyxx/nyxx.dart';
import 'package:get_it/get_it.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';
import 'package:translation_bot/commands/detect.dart';
import 'package:translation_bot/commands/languages.dart';
import 'package:translation_bot/commands/message_detect.dart';
import 'package:translation_bot/commands/message_translate.dart';
import 'package:translation_bot/commands/ping.dart';
import 'package:translation_bot/commands/shadow_me.dart';
import 'package:translation_bot/commands/translate.dart';
import 'package:translation_bot/converters/language.dart';
import 'package:translation_bot/errors.dart';
import 'package:translation_bot/plugins/shadow_users.dart';
import 'package:translation_bot/plugins/status_rotate.dart';

void main() async {
  final libreTranslate = LibreTranslateClient(base: Uri.http('libretranslate:5000'));
  final availableLanguages = await libreTranslate.listLanguages();

  final commands = CommandsPlugin(
    prefix: mentionOr((_) => Platform.environment['PREFIX']!),
    options: CommandsOptions(logErrors: false),
  );

  commands
    ..addCommand(ping)
    ..addCommand(detect)
    ..addCommand(translate)
    ..addCommand(languages)
    ..addCommand(messageDetect)
    ..addCommand(messageTranslate)
    ..addCommand(shadowMe)
    ..addConverter(languageConverter);

  GetIt.I.registerSingleton(pagination);
  GetIt.I.registerSingleton(commands);
  GetIt.I.registerSingleton(libreTranslate);
  GetIt.I.registerSingleton(availableLanguages);

  final shadowUsers = ShadowUsers();

  GetIt.I.registerSingleton(shadowUsers);

  final client = await Nyxx.connectGateway(
    Platform.environment['TOKEN']!,
    GatewayIntents.allUnprivileged | GatewayIntents.messageContent,
    options: GatewayClientOptions(plugins: [
      logging,
      cliIntegration,
      ignoreExceptions,
      commands,
      pagination,
      StatusRotate(),
      shadowUsers,
    ]),
  );

  GetIt.I.registerSingleton(client);

  pagination.onDisallowedUse.listen((event) async {
    await event.interaction.respond(
      isEphemeral: true,
      MessageBuilder(embeds: [
        EmbedBuilder(
          title: 'Pagination restricted to creator',
          color: DiscordColor.fromRgb(255, 0, 0),
          description:
              'Sorry, changing pages is reserved for the user who ran the command. Run the same command yourself if you want to scroll through the output.',
        )
      ]),
    );
  });

  pagination.onUnhandledInteraction.listen((event) async {
    await event.interaction.respond(
      isEphemeral: true,
      MessageBuilder(embeds: [
        EmbedBuilder(
          title: 'Controls expired',
          color: DiscordColor.fromRgb(255, 0, 0),
          description:
              'Sorry, these controls no longer work. Run the command again to get working controls.',
        )
      ]),
    );
  });

  commands.onCommandError.listen((error) async {
    if (error case ContextualException(:final InteractiveContext context)) {
      if (error is BadInputException) {
        await context.respond(
          level: ResponseLevel.hint,
          MessageBuilder(embeds: [
            EmbedBuilder(
              title: 'Invalid input',
              color: DiscordColor.fromRgb(255, 0, 0),
              description: error.message,
            ),
          ]),
        );
      } else if (error is UnhandledInteractionException) {
        await context.respond(
          level: ResponseLevel.hint,
          MessageBuilder(embeds: [
            EmbedBuilder(
              title: 'Component expired',
              color: DiscordColor.fromRgb(255, 0, 0),
              description: 'Sorry, this component no longer works. Try running the command again.',
            ),
          ]),
        );
      } else if (error is CheckFailedException) {
        // TODO: Check what failed.

        await context.respond(
          level: ResponseLevel.hint,
          MessageBuilder(embeds: [
            EmbedBuilder(
              title: 'Checks failed',
              color: DiscordColor.fromRgb(255, 0, 0),
              description: "Sorry, you can't use this command right now.",
            ),
          ]),
        );
      } else if (error is UncaughtException) {
        final exception = error.exception;

        if (exception is InputRequiredException) {
          await context.respond(
            level: ResponseLevel.hint,
            MessageBuilder(embeds: [
              EmbedBuilder(
                title: 'Input required',
                color: DiscordColor.fromRgb(255, 0, 0),
                description: "This command requires input.",
              ),
            ]),
          );
        } else if (exception is LibreTranslateException) {
          await context.respond(
            level: ResponseLevel.hint,
            MessageBuilder(embeds: [
              EmbedBuilder(
                title: 'LibreTranslate error',
                color: DiscordColor.fromRgb(255, 0, 0),
                description: "Sorry, an error occurred while processing your command.",
                fields: [
                  EmbedFieldBuilder(name: 'Details', value: exception.message, isInline: false),
                ],
              ),
            ]),
          );
        } else {
          commands.logger.shout('Unhandled exception', exception, error.stackTrace);
        }
      }
    } else {
      commands.logger.warning('Unhandled exception', error, error.stackTrace);
    }
  });
}
