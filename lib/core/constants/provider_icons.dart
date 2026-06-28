class ProviderIcons {
  static const Map<String, String> providers = {
    'netflix': 'assets/icons/providers/netflix.png',
    'spotify': 'assets/icons/providers/spotify.png',
    'prime_video': 'assets/icons/providers/prime_video.png',
    'chatgpt': 'assets/icons/providers/chatgpt.png',
    'claude': 'assets/icons/providers/claude.png',
    'disney_plus': 'assets/icons/providers/disney_plus.png',
    'youtube_premium': 'assets/icons/providers/youtube_premium.png',
    'jiohotstar': 'assets/icons/providers/jiohotstar.png',
    'apple_music': 'assets/icons/providers/apple_music.png',
    'microsoft_365': 'assets/icons/providers/microsoft_365.png',
    'notion': 'assets/icons/providers/notion.png',
    'figma': 'assets/icons/providers/figma.png',
    'custom': 'assets/icons/providers/custom.png',
  };

  static const List<String> providerNames = [
    'Netflix',
    'Spotify',
    'Prime Video',
    'ChatGPT',
    'Claude',
    'Disney+',
    'YouTube Premium',
    'JioHotstar',
    'Apple Music',
    'Microsoft 365',
    'Notion',
    'Figma',
    'Custom',
  ];

  static String iconForProvider(String provider) {
    final key = provider.toLowerCase().replaceAll(' ', '_').replaceAll('+', '_plus');
    return providers[key] ?? providers['custom']!;
  }
}
