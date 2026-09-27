import re

path = r'D:\radyjko\lib\screens\player_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

pattern = r'final controller = TextEditingController\(text: customLogo \?\? \'\'\);.*?builder: \(ctx\) => AlertDialog\(.*?\]\,\s*\)\,\s*\)\;'

replacement = '''final result = await showDialog<String>(
                      context: context,
                      builder: (ctx) => LogoEditorDialog(
                        station: station,
                        currentLogo: customLogo,
                      ),
                    );'''

content = re.sub(pattern, replacement, content, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
