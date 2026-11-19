/// Villes proposées en premier dans le champ « Ville » (saisie libre
/// acceptée). Principales villes du Burkina Faso, par ordre alphabétique
/// après les deux plus grandes.
const burkinaCities = <String>[
  'Ouagadougou',
  'Bobo-Dioulasso',
  'Banfora',
  'Dédougou',
  'Diébougou',
  'Dori',
  'Fada N’Gourma',
  'Gaoua',
  'Kaya',
  'Kombissiri',
  'Konsa',
  'Koudougou',
  'Koupéla',
  'Léo',
  'Manga',
  'Nouna',
  'Ouahigouya',
  'Pô',
  'Réo',
  'Tenkodogo',
  'Tougan',
  'Yako',
  'Ziniaré',
  'Zorgho',
];

/// Villes de la liste commençant par (ou contenant) [query], sans tenir
/// compte des accents ni de la casse ; les débuts de mot d'abord.
List<String> suggestCities(String query, {int limit = 6}) {
  final q = foldAccents(query.trim());
  if (q.isEmpty) return burkinaCities.take(limit).toList();
  final starts = <String>[];
  final contains = <String>[];
  for (final city in burkinaCities) {
    final folded = foldAccents(city);
    if (folded.startsWith(q)) {
      starts.add(city);
    } else if (folded.contains(q)) {
      contains.add(city);
    }
  }
  return [...starts, ...contains].take(limit).toList();
}

/// Minuscules sans accents, pour comparer des saisies.
String foldAccents(String text) {
  const from = 'àâäáãéèêëíìîïóòôöõúùûüçñ’';
  const to = "aaaaaeeeeiiiiooooouuuucn'";
  final buffer = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final index = from.indexOf(char);
    buffer.write(index < 0 ? char : to[index]);
  }
  return buffer.toString();
}
