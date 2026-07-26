class CountryCode {
  final String name;
  final String code;
  final String flag;
  final int minLength;
  final int maxLength;

  const CountryCode({
    required this.name,
    required this.code,
    required this.flag,
    this.minLength = 7,
    this.maxLength = 15,
  });
}

const List<CountryCode> countries = [
  CountryCode(name: 'United States', code: '+1', flag: '🇺🇸', minLength: 10, maxLength: 10),
  CountryCode(name: 'India', code: '+91', flag: '🇮🇳', minLength: 10, maxLength: 10),
  CountryCode(name: 'United Kingdom', code: '+44', flag: '🇬🇧', minLength: 10, maxLength: 10),
  CountryCode(name: 'Canada', code: '+1', flag: '🇨🇦', minLength: 10, maxLength: 10),
  CountryCode(name: 'Australia', code: '+61', flag: '🇦🇺', minLength: 9, maxLength: 9),
  CountryCode(name: 'Germany', code: '+49', flag: '🇩🇪', minLength: 10, maxLength: 11),
  CountryCode(name: 'France', code: '+33', flag: '🇫🇷', minLength: 9, maxLength: 9),
  CountryCode(name: 'Japan', code: '+81', flag: '🇯🇵', minLength: 10, maxLength: 10),
  CountryCode(name: 'Singapore', code: '+65', flag: '🇸🇬', minLength: 8, maxLength: 8),
  CountryCode(name: 'United Arab Emirates', code: '+971', flag: '🇦🇪', minLength: 9, maxLength: 9),
  CountryCode(name: 'Saudi Arabia', code: '+966', flag: '🇸🇦', minLength: 9, maxLength: 9),
  CountryCode(name: 'South Africa', code: '+27', flag: '🇿🇦', minLength: 9, maxLength: 9),
  CountryCode(name: 'Brazil', code: '+55', flag: '🇧🇷', minLength: 11, maxLength: 11),
  CountryCode(name: 'Mexico', code: '+52', flag: '🇲🇽', minLength: 10, maxLength: 10),
  CountryCode(name: 'New Zealand', code: '+64', flag: '🇳🇿', minLength: 8, maxLength: 10),
  CountryCode(name: 'Russia', code: '+7', flag: '🇷🇺', minLength: 10, maxLength: 10),
  CountryCode(name: 'China', code: '+86', flag: '🇨🇳', minLength: 11, maxLength: 11),
  CountryCode(name: 'Italy', code: '+39', flag: '🇮🇹', minLength: 9, maxLength: 10),
  CountryCode(name: 'Spain', code: '+34', flag: '🇪🇸', minLength: 9, maxLength: 9),
  CountryCode(name: 'Netherlands', code: '+31', flag: '🇳🇱', minLength: 9, maxLength: 9),
  CountryCode(name: 'Sweden', code: '+46', flag: '🇸🇪', minLength: 9, maxLength: 9),
  CountryCode(name: 'Switzerland', code: '+41', flag: '🇨🇭', minLength: 9, maxLength: 9),
  CountryCode(name: 'Turkey', code: '+90', flag: '🇹🇷', minLength: 10, maxLength: 10),
  CountryCode(name: 'Malaysia', code: '+60', flag: '🇲🇾', minLength: 9, maxLength: 10),
  CountryCode(name: 'Indonesia', code: '+62', flag: '🇮🇩', minLength: 10, maxLength: 12),
  CountryCode(name: 'Philippines', code: '+63', flag: '🇵🇭', minLength: 10, maxLength: 10),
  CountryCode(name: 'Thailand', code: '+66', flag: '🇹🇭', minLength: 9, maxLength: 9),
  CountryCode(name: 'Vietnam', code: '+84', flag: '🇻🇳', minLength: 9, maxLength: 9),
  CountryCode(name: 'Pakistan', code: '+92', flag: '🇵🇰', minLength: 10, maxLength: 10),
  CountryCode(name: 'Bangladesh', code: '+880', flag: '🇧🇩', minLength: 10, maxLength: 10),
  CountryCode(name: 'Nigeria', code: '+234', flag: '🇳🇬', minLength: 10, maxLength: 10),
  CountryCode(name: 'Kenya', code: '+254', flag: '🇰🇪', minLength: 9, maxLength: 9),
  CountryCode(name: 'Argentina', code: '+54', flag: '🇦🇷', minLength: 10, maxLength: 10),
  CountryCode(name: 'Colombia', code: '+57', flag: '🇨🇴', minLength: 10, maxLength: 10),
  CountryCode(name: 'Egypt', code: '+20', flag: '🇪🇬', minLength: 10, maxLength: 10),
  CountryCode(name: 'Ireland', code: '+353', flag: '🇮🇪', minLength: 9, maxLength: 9),
  CountryCode(name: 'Belgium', code: '+32', flag: '🇧🇪', minLength: 9, maxLength: 9),
  CountryCode(name: 'Austria', code: '+43', flag: '🇦🇹', minLength: 10, maxLength: 13),
  CountryCode(name: 'Norway', code: '+47', flag: '🇳🇴', minLength: 8, maxLength: 8),
  CountryCode(name: 'Denmark', code: '+45', flag: '🇩🇰', minLength: 8, maxLength: 8),
  CountryCode(name: 'Finland', code: '+358', flag: '🇫🇮', minLength: 5, maxLength: 12),
  CountryCode(name: 'Greece', code: '+30', flag: '🇬🇷', minLength: 10, maxLength: 10),
  CountryCode(name: 'Portugal', code: '+351', flag: '🇵🇹', minLength: 9, maxLength: 9),
  CountryCode(name: 'Poland', code: '+48', flag: '🇵🇱', minLength: 9, maxLength: 9),
];
