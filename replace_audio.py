import re

path = r'D:\radyjko\lib\services\audio_handler.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('Future<void> play() => _player.play();', '''Future<void> play() async {
    if (mediaItem.value != null) {
      _player.setUrl(mediaItem.value!.id).catchError((_) {});
      await _player.play();
    } else {
      await _player.play();
    }
  }''')

content = content.replace('Future<void> pause() => _player.pause();', '''Future<void> pause() async {
    // W aplikacji radiowej pauza powinna fizycznie zatrzymać strumień (stop),
    // aby nie zużywać danych komórkowych i uniknąć słuchania przeszłości po wznowieniu.
    await _player.stop();
  }''')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
