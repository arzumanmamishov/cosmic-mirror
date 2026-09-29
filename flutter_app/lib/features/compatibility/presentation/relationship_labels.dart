import 'package:cosmic_mirror/l10n/app_localizations.dart';

/// Relationship ids as stored on the backend. Never localize these values —
/// map them to display labels with [relationshipLabel].
const relationshipIds = [
  'Partner', 'Friend', 'Family', 'Coworker', 'Crush', 'Other',
];

/// Localized display label for a stored relationship id. Unknown values are
/// returned unchanged.
String relationshipLabel(AppLocalizations l, String id) {
  switch (id.toLowerCase()) {
    case 'partner':
      return l.compatRelPartner;
    case 'friend':
      return l.compatRelFriend;
    case 'family':
      return l.compatRelFamily;
    case 'coworker':
      return l.compatRelCoworker;
    case 'crush':
      return l.compatRelCrush;
    case 'other':
      return l.compatRelOther;
    default:
      return id;
  }
}
