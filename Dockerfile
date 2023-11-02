FROM dart:stable

WORKDIR /bot

# Install dependencies
COPY pubspec.* /bot/
RUN dart pub get

# Copy code
COPY . /bot/
RUN dart pub get --offline

# Compile bot into executable
RUN dart run nyxx_commands:compile --compile -o translation_bot.g.dart --no-compile bin/translation_bot.dart
RUN dart compile exe -o translation_bot translation_bot.g.dart

CMD [ "./translation_bot" ]
