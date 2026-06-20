// Catálogo de assets do avatar (gatos + olhos) hospedados no R2/CDN.
// Fonte única de verdade para as opções de raça/olho e seus arquivos PNG.

/// Raças selecionáveis: (valor persistido, rótulo exibido, arquivo PNG do gato).
const avatarBreeds = <(String value, String label, String file)>[
  ('black',           'Preto',          'black-cat.webp'),
  ('blue-point',      'Blue point',     'blue-point-cat.webp'),
  ('malhado',         'Malhado',        'malhado-cat.webp'),
  ('malhado-orange',  'Malhado Laranja','malhado-orange-cat.webp'),
  ('orange',          'Laranja',        'orange-cat.webp'),
  ('red-point',       'Point Vermelho', 'red-point-cat.webp'),
  ('chocolate-point', 'Chocolate',      'chocolate-point-cat.webp'),
  ('tabby-brown',     'Rajado Marrom',  'tabby-brown-cat.webp'),
  ('tabby-gray',      'Rajado Cinza',   'tabby-gray-cat.webp'),
  ('tabby-orange',    'Rajado Laranja', 'tabby-orange-cat.webp'),
  ('trica',           'Tricolor',       'trica-cat.webp'),
  ('tuxedo',          'Frajola',         'tuxedo-cat-1.webp'),
  ('tuxedo-green',    'Frajola padrão',  'tuxedo-cat-2.webp'),
  ('tuxedo-gray',     'Frajola cinza',   'tuxedo-gray-cat.webp'),
  ('tuxedo-spotted',  'Frajola manchado','tuxedo-cat-3.webp'),
  ('white',           'Branco',          'white-cat.webp'),
];

/// Gato branco — usado como fallback quando a raça é desconhecida ou a imagem falha.
const avatarFallbackCatFile = 'white-cat.webp';

/// Arquivo PNG do gato para a raça informada (cai no fallback branco se não houver).
String catFileForBreed(String breed) {
  for (final b in avatarBreeds) {
    if (b.$1 == breed) return b.$3;
  }
  return avatarFallbackCatFile;
}

/// Olhos selecionáveis: (valor persistido, rótulo, emoji do indicador de cor).
/// O primeiro item é o padrão — a imagem base da raça não tem olhos, então
/// o olho é sempre sobreposto.
const avatarEyes = <(String value, String label, String emoji)>[
  ('blue',   'Azul',     '🔵'),
  ('green',  'Verde',    '🟢'),
  ('pink',   'Rosa',     '🩷'),
  ('purple', 'Roxo',     '🟣'),
  ('yellow', 'Âmbar',    '🟡'),
];

/// Olho padrão (primeiro da lista) — usado quando nenhum foi selecionado.
const avatarDefaultEye = 'blue';

const _eyeFiles = <String, String>{
  'blue':   'blue-eye.webp',
  'green':  'green-eye.webp',
  'pink':   'pink-eye.webp',
  'purple': 'purple-eye.webp',
  'yellow': 'yellow-eye.webp',
};

/// Arquivo PNG do olho a ser sobreposto (sempre há overlay, pois a base da
/// raça não tem olhos desenhados). Cai no olho padrão se a cor for desconhecida.
String eyeFileForColor(String eyeColor) =>
    _eyeFiles[eyeColor] ?? _eyeFiles[avatarDefaultEye]!;

/// Cenários de fundo: (valor persistido, rótulo, emoji, arquivo PNG).
/// O fundo é desenhado atrás do gato. Valor vazio/nulo = sem cenário.
const avatarBackgrounds = <(String value, String label, String emoji, String file)>[
  ('verao',         'Verão',         '☀️',  'verao.webp'),
  ('outono',        'Outono',        '🍂',  'outono.webp'),
  ('inverno',       'Inverno',       '❄️',  'inverno.webp'),
  ('primavera',     'Primavera',     '🌸',  'primavera.webp'),
  ('konoha',        'Konoha',        '🍃',  'konoha.webp'),
  ('one-piece',     'One Piece',     '🏴‍☠️', 'grandline.webp'),
  ('hero-academia', 'Hero Academia', '💥',  'UA.webp'),
];

/// Arquivo PNG do cenário, ou `null` quando não há cenário selecionado.
String? backgroundFileForValue(String? value) {
  if (value == null || value.isEmpty) return null;
  for (final b in avatarBackgrounds) {
    if (b.$1 == value) return b.$4;
  }
  return null;
}
