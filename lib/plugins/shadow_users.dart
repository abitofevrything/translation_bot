import 'package:get_it/get_it.dart';
import 'package:libre_translate/libre_translate.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';

class ShadowUsers extends NyxxPlugin<NyxxGateway> {
  static const duration = Duration(hours: 1);

  final Map<(Snowflake userId, Snowflake channelId), (Language language, DateTime start)> users =
      {};

  @override
  void afterConnect(NyxxGateway client) {
    client.onMessageCreate.listen((event) async {
      final request = users[(event.message.author.id, event.message.channelId)];
      if (request == null) return;

      final (language, start) = request;

      if (start.isBefore(DateTime.timestamp().add(-duration))) {
        users.remove((event.message.author.id, event.message.channelId));
        return;
      }

      try {
        if (event.message.content.trim().isEmpty) return;

        final libreTranslate = GetIt.I.get<LibreTranslateClient>();
        final availableLanguages = GetIt.I.get<List<Language>>();

        final detected = (await libreTranslate.detect(event.message.content))
            .entries
            .fold<MapEntry<String, double>?>(
                null,
                (previousValue, element) =>
                    previousValue == null || element.value > previousValue.value
                        ? element
                        : previousValue);

        if (detected == null) {
          return;
        }

        final from = availableLanguages.singleWhere((element) => element.code == detected.key);

        final translated = await libreTranslate.translate(event.message.content,
            source: from.code, target: language.code);

        await event.message.channel.sendMessage(await pagination.split(
          translated,
          maxLength: 1500,
          buildChunk: (chunk) => MessageBuilder(
            replyId: event.message.id,
            content: 'Shadow translate (`/shadow-me stop` to stop): $chunk',
            allowedMentions: AllowedMentions(parse: [], repliedUser: true),
          ),
        ));
      } on LibreTranslateException {
        // Eh, it's probably fine.
      }
    });
  }
}
