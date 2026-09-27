import re

path = r'D:\radyjko\lib\services\audio_handler.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

pattern = r'Future<void> stop\(\) async \{.*?await super\.stop\(\);\s*\}'
replacement = '''Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }'''

content = re.sub(pattern, replacement, content, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
