import re

path = r'D:\radyjko\lib\providers\radio_provider.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

pattern = r'String\? getCustomLogo\(String stationUuid\) => _customLogos\[stationUuid\];'
replace = '''String? getCustomLogo(String stationUuid) {
    var logo = _customLogos[stationUuid];
    if (logo != null && logo.contains('logo.clearbit.com')) {
      return logo.replaceAll('logo.clearbit.com', 'icon.horse/icon');
    }
    return logo;
  }'''
content = re.sub(pattern, replace, content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
