import Foundation

// MARK: - Display Extensions for UI
extension EngineType {
  public var displayName: String {
    switch self {
    case .single: return "Одноцилиндровый"
    case .parallelTwin: return "Параллельный близнец"
    case .inline4: return "Рядная четверка"
    case .vTwin: return "V-образный близнец"
    case .vTwinTestastretta: return "V-образный близнец Testastretta"
    case .vTwinTestastrettaDVT: return "V-образный близнец Testastretta DVT"
    case .v4: return "V4"
    case .v4Granturismo: return "V4 Granturismo"
    case .flat6: return "Плоская шестерка"
    case .boxer: return "Оппозитный"
    case .triple: return "Трехцилиндровый"
    case .inline3: return "Рядная тройка"
    case .unknown: return "Неизвестно"
    }
  }
}

extension CoolingSystem {
  public var displayName: String {
    switch self {
    case .liquid: return "Жидкостное"
    case .air: return "Воздушное"
    case .oil: return "Масляное"
    case .unknown: return "Неизвестно"
    }
  }
}

extension Gearbox {
  public var displayName: String {
    switch self {
    case .speed4: return "4-ступенчатая"
    case .speed5: return "5-ступенчатая"
    case .speed6: return "6-ступенчатая"
    case .speed7: return "7-ступенчатая"
    case .cvt: return "CVT"
    case .automatic: return "Автоматическая"
    case .unknown: return "Неизвестно"
    }
  }
}

extension TransmissionType {
  public var displayName: String {
    switch self {
    case .manual: return "Механическая"
    case .dct: return "DCT"
    case .automatic: return "Автоматическая"
    case .semiAutomatic: return "Полуавтоматическая"
    case .unknown: return "Неизвестно"
    }
  }
}

extension BrakeType {
  public var displayName: String {
    switch self {
    case .disc: return "Дисковые"
    case .dualDisc: return "Двойные дисковые"
    case .singleDisc: return "Одинарные дисковые"
    case .drum: return "Барабанные"
    case .abs: return "ABS"
    case .combined: return "Комбинированные"
    case .unknown: return "Неизвестно"
    }
  }
}

extension StarterType {
  public var displayName: String {
    switch self {
    case .electric: return "Электрический"
    case .kick: return "Кик-стартер"
    case .electricKick: return "Электрический/Кик"
    case .unknown: return "Неизвестно"
    }
  }
}

// MARK: - Convenience Extensions
extension MotorInfo.ModelInfo {
  /// Краткое описание двигателя
  public var engineDescription: String {
    return "\(displacement)cc \(engineType.displayName)"
  }
  
  /// Краткое описание трансмиссии
  public var transmissionDescription: String {
    return "\(gearbox.displayName) \(transmission.displayName)"
  }
  
  /// Краткое описание подвески
  public var suspensionDescription: String {
    return "\(frontSuspension.displayName) / \(rearSuspension.displayName)"
  }
  
  /// Краткое описание тормозов
  public var brakeDescription: String {
    return "\(frontBrake.displayName) / \(rearBrake.displayName)"
  }
}
