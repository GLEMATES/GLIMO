/// Helper untuk mapping komponen servis dengan gambar dan deskripsi
class ComponentInfo {
  final String imagePath;
  final String description;

  const ComponentInfo({
    required this.imagePath,
    required this.description,
  });
}

/// Mapping komponen dengan gambar dan deskripsi
class ComponentInfoHelper {
  static const Map<String, ComponentInfo> _componentInfoMap = {
    'Filter Udara': ComponentInfo(
      imagePath: 'assets/images/filter_udara.png',
      description: 'Komponen yang menyaring udara yang masuk ke mesin.',
    ),
    'Rantai & Gir': ComponentInfo(
      imagePath: 'assets/images/rantai_gir.png',
      description: 'Komponen penting untuk transmisi tenaga pada motor.',
    ),
    'Oli Mesin': ComponentInfo(
      imagePath: 'assets/images/oli_mesin.png',
      description: 'Cairan pelumas utama dalam mesin untuk mengurangi gesekan antar komponen mesin.',
    ),
    'Oli Gardan': ComponentInfo(
      imagePath: 'assets/images/oli_gardan.png',
      description: 'Pelumas khusus untuk sistem transmisi otomatis dan gardan pada motor.',
    ),
    'V-Belt': ComponentInfo(
      imagePath: 'assets/images/v_belt.png',
      description: 'Komponen yang menyalurkan tenaga dari mesin ke roda belakang pada motor matic.',
    ),
    'Kampas Rem': ComponentInfo(
      imagePath: 'assets/images/kampas_rem.png',
      description: 'Komponen penting dalam sistem pengereman yang berfungsi untuk memperlambat atau menghentikan putaran roda.',
    ),
    'Busi': ComponentInfo(
      imagePath: 'assets/images/busi.png',
      description: 'Komponen yang menghasilkan percikan api untuk membakar campuran bahan bakar dan udara di ruang bakar mesin.',
    ),
    'Aki': ComponentInfo(
      imagePath: 'assets/images/aki.png',
      description: 'Sumber tenaga listrik utama untuk sistem starter, lampu, klakson, dan komponen kelistrikan motor lainnya.',
    ),
  };

  /// Get component info by component name
  static ComponentInfo? getComponentInfo(String componentName) {
    // Try exact match first
    if (_componentInfoMap.containsKey(componentName)) {
      return _componentInfoMap[componentName];
    }

    // Try case-insensitive match
    final lowerComponentName = componentName.toLowerCase();
    for (var entry in _componentInfoMap.entries) {
      if (entry.key.toLowerCase() == lowerComponentName) {
        return entry.value;
      }
    }

    // Try partial match (e.g., "Oli Mesin SAE 10W-30" matches "Oli Mesin")
    for (var entry in _componentInfoMap.entries) {
      if (lowerComponentName.contains(entry.key.toLowerCase()) ||
          entry.key.toLowerCase().contains(lowerComponentName)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Check if component has info available
  static bool hasComponentInfo(String componentName) {
    return getComponentInfo(componentName) != null;
  }

  /// Get all available components
  static List<String> getAllComponents() {
    return _componentInfoMap.keys.toList();
  }
}
