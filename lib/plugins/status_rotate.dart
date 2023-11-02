import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:libre_translate/libre_translate.dart';
import 'package:nyxx/nyxx.dart';

class StatusRotate extends NyxxPlugin<NyxxGateway> {
  static const updateInterval = Duration(seconds: 30);

  final statuses = [
    'Translating text | /translate',
    '${GetIt.I.get<List<Language>>().length} languages available | /languages',
    'Detecting languages | /detect',
  ];

  @override
  NyxxPluginState<NyxxGateway, StatusRotate> createState() => _StatusRotateState(this);
}

class _StatusRotateState extends NyxxPluginState<NyxxGateway, StatusRotate> {
  _StatusRotateState(super.client);

  Timer? timer;
  int index = 0;

  void updateStatus(NyxxGateway client) async {
    final status = plugin.statuses[index++ % plugin.statuses.length];

    client.updatePresence(PresenceBuilder(
      status: CurrentUserStatus.online,
      isAfk: false,
      activities: [ActivityBuilder(name: status, type: ActivityType.custom, state: status)],
    ));
  }

  @override
  void afterConnect(NyxxGateway client) {
    super.afterConnect(client);
    updateStatus(client);
    Timer(StatusRotate.updateInterval, () => updateStatus(client));
  }

  @override
  void beforeClose(NyxxGateway client) {
    super.beforeClose(client);
    timer?.cancel();
  }
}
