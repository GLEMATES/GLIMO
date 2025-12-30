enum UserCategory {
  light,
  medium,
  heavy,
}

class UserCategoryInfo {
  final UserCategory category;
  final String label;
  final String emoji;
  final String description;

  const UserCategoryInfo({
    required this.category,
    required this.label,
    required this.emoji,
    required this.description,
  });

  static const Map<UserCategory, UserCategoryInfo> categoryMap = {
    UserCategory.light: UserCategoryInfo(
      category: UserCategory.light,
      label: 'Light User',
      emoji: '🟢',
      description: 'Penggunaan rendah, cocok untuk efisiensi bahan bakar dan perawatan minimal',
    ),
    UserCategory.medium: UserCategoryInfo(
      category: UserCategory.medium,
      label: 'Medium User',
      emoji: '🟡',
      description: 'Penggunaan seimbang untuk kebutuhan harian, perlu perawatan rutin',
    ),
    UserCategory.heavy: UserCategoryInfo(
      category: UserCategory.heavy,
      label: 'Heavy User',
      emoji: '🔴',
      description: 'Penggunaan intensif, perhatikan perawatan ekstra dan penggantian komponen lebih sering',
    ),
  };

  static UserCategoryInfo getInfo(UserCategory category) {
    return categoryMap[category]!;
  }
}

class MonthlyUsageData {
  final double avgKmPerTrip;
  final double totalKmPerMonth;
  final double tripsPerWeek;
  final double trendSlope;
  final UserCategory? actualCategory;

  MonthlyUsageData({
    required this.avgKmPerTrip,
    required this.totalKmPerMonth,
    required this.tripsPerWeek,
    required this.trendSlope,
    this.actualCategory,
  });

  List<double> toVector() => [
        avgKmPerTrip,
        totalKmPerMonth,
        tripsPerWeek,
        trendSlope,
      ];
}

class HistoricalDataGenerator {
  static List<MonthlyUsageData> generate12MonthsData() {
    final data = <MonthlyUsageData>[];

    data.addAll(_generateLightUserData());
    data.addAll(_generateMediumUserData());
    data.addAll(_generateHeavyUserData());

    return data;
  }

  static List<MonthlyUsageData> _generateLightUserData() {
    return List.generate(12, (i) {
      return MonthlyUsageData(
        avgKmPerTrip: 15.0 + (i * 0.5),
        totalKmPerMonth: 200.0 + (i * 15),
        tripsPerWeek: 4.0 + (i * 0.1),
        trendSlope: 0.05 + (i * 0.003),
        actualCategory: UserCategory.light,
      );
    });
  }

  static List<MonthlyUsageData> _generateMediumUserData() {
    return List.generate(12, (i) {
      return MonthlyUsageData(
        avgKmPerTrip: 25.0 + (i * 0.7),
        totalKmPerMonth: 600.0 + (i * 25),
        tripsPerWeek: 9.0 + (i * 0.15),
        trendSlope: 0.12 + (i * 0.005),
        actualCategory: UserCategory.medium,
      );
    });
  }

  static List<MonthlyUsageData> _generateHeavyUserData() {
    return List.generate(12, (i) {
      return MonthlyUsageData(
        avgKmPerTrip: 40.0 + (i * 1.0),
        totalKmPerMonth: 1500.0 + (i * 80),
        tripsPerWeek: 20.0 + (i * 0.3),
        trendSlope: 0.25 + (i * 0.008),
        actualCategory: UserCategory.heavy,
      );
    });
  }

  static MonthlyUsageData getCurrentUserData() {
    return MonthlyUsageData(
      avgKmPerTrip: 28.0,
      totalKmPerMonth: 650.0,
      tripsPerWeek: 10.0,
      trendSlope: 0.15,
    );
  }
}
