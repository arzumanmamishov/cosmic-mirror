/// Mock data for the redesigned Home screen sections (astrologers, discussions).
/// All copy is warm and modern - no lorem ipsum.
library;

class Astrologer {
  const Astrologer({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.imageUrl,
    required this.online,
  });

  final String name;
  final String specialty;
  final double rating;
  final String imageUrl;
  final bool online;
}

class Discussion {
  const Discussion({
    required this.title,
    required this.author,
    required this.replies,
    required this.tag,
    required this.timeAgo,
  });

  final String title;
  final String author;
  final int replies;
  final String tag;
  final String timeAgo;
}

const List<Astrologer> mockAstrologers = [
  Astrologer(
    name: 'Lilith Cooper',
    specialty: 'Vedic Astrology',
    rating: 5.0,
    imageUrl:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&q=80',
    online: true,
  ),
  Astrologer(
    name: 'Noah Reed',
    specialty: 'Career & Finance',
    rating: 4.8,
    imageUrl:
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&q=80',
    online: true,
  ),
  Astrologer(
    name: 'Selene Hart',
    specialty: 'Love & Relationships',
    rating: 4.5,
    imageUrl:
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200&q=80',
    online: false,
  ),
  Astrologer(
    name: 'Milena Hayes',
    specialty: 'Tarot & Intuition',
    rating: 4.5,
    imageUrl:
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
    online: true,
  ),
  Astrologer(
    name: 'Theo Marlow',
    specialty: 'Natal Chart Reading',
    rating: 4.7,
    imageUrl:
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&q=80',
    online: false,
  ),
];

const List<Discussion> mockDiscussions = [
  Discussion(
    title: 'How does Saturn return actually feel?',
    author: 'Maya P.',
    replies: 42,
    tag: 'Saturn Return',
    timeAgo: '2h',
  ),
  Discussion(
    title: 'My Pisces moon experience: tips for highly sensitive people',
    author: 'River K.',
    replies: 28,
    tag: 'Moon Signs',
    timeAgo: '5h',
  ),
  Discussion(
    title: 'Mercury retrograde survival guide for Geminis',
    author: 'Aiden T.',
    replies: 17,
    tag: 'Transits',
    timeAgo: '1d',
  ),
  Discussion(
    title: 'Reading my synastry chart with my partner -- mind blown',
    author: 'Lila M.',
    replies: 56,
    tag: 'Compatibility',
    timeAgo: '1d',
  ),
];
