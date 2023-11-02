import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

String formatDuration(Duration duration) =>
    '${(duration.inMicroseconds / Duration.microsecondsPerMillisecond).toStringAsFixed(2)}ms';

final ping = ChatCommand(
  'ping',
  'Check the bot is online',
  id('ping', (ChatContext context) async {
    await context.respond(MessageBuilder(embeds: [
      EmbedBuilder(
        title: 'Pong!',
        color: DiscordColor.fromRgb(0, 162, 255),
        fields: [
          EmbedFieldBuilder(
            name: 'HTTP latency',
            value: formatDuration(context.client.httpHandler.latency),
            isInline: true,
          ),
          EmbedFieldBuilder(
            name: 'Network latency',
            value: formatDuration(context.client.httpHandler.realLatency),
            isInline: true,
          ),
          EmbedFieldBuilder(
            name: 'Gateway latency',
            value: formatDuration(context.client.gateway.latency),
            isInline: true,
          ),
        ],
      ),
    ]));
  }),
);
