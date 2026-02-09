import Foundation

/// Шаблон регулярного сервиса
public struct ServiceTemplate: Codable, Identifiable, Hashable {
  public let id: String
  public let name: Name
  public let defaultMileageInterval: Int? // км (nil если не по пробегу)
  public let defaultTimeInterval: Int? // дни (nil если не по времени)
  public let category: Category
  
  public init(
    id: String = UUID().uuidString,
    name: Name,
    defaultMileageInterval: Int? = nil,
    defaultTimeInterval: Int? = nil,
    category: Category
  ) {
    self.id = id
    self.name = name
    self.defaultMileageInterval = defaultMileageInterval
    self.defaultTimeInterval = defaultTimeInterval
    self.category = category
  }
  
  /// Тип сервиса (enum для структуризации)
  public enum Name: String, Codable, CaseIterable {
    case oilChange = "oil_change"
    case oilFilterChange = "oil_filter_change"
    case airFilterChange = "air_filter_change"
    case sparkPlugsChange = "spark_plugs_change"
    case valveAdjustment = "valve_adjustment"
    case chainLubrication = "chain_lubrication"
    case chainReplacement = "chain_replacement"
    case brakePadsChange = "brake_pads_change"
    case brakeFluidChange = "brake_fluid_change"
    case coolantChange = "coolant_change"
    
    /// Локализованное название для отображения
    public var displayName: String {
      switch self {
      case .oilChange: return "Замена масла"
      case .oilFilterChange: return "Замена масляного фильтра"
      case .airFilterChange: return "Замена воздушного фильтра"
      case .sparkPlugsChange: return "Замена свечей зажигания"
      case .valveAdjustment: return "Проверка/регулировка клапанов"
      case .chainLubrication: return "Смазка цепи"
      case .chainReplacement: return "Замена цепи"
      case .brakePadsChange: return "Замена тормозных колодок"
      case .brakeFluidChange: return "Замена тормозной жидкости"
      case .coolantChange: return "Замена охлаждающей жидкости"
      }
    }
  }
  
  /// Категория сервиса
  public enum Category: String, Codable, CaseIterable {
    case engine = "engine"
    case transmission = "transmission"
    case brakes = "brakes"
    case cooling = "cooling"
    case other = "other"
    
    public var displayName: String {
      switch self {
      case .engine: return "Двигатель"
      case .transmission: return "Трансмиссия"
      case .brakes: return "Тормоза"
      case .cooling: return "Охлаждение"
      case .other: return "Прочее"
      }
    }
  }
}

// MARK: - Предустановленные шаблоны
public extension ServiceTemplate {
  /// Все предустановленные шаблоны сервисов
  static var allTemplates: [ServiceTemplate] {
    [
      // Двигатель
      ServiceTemplate(
        id: "template_oil_change",
        name: .oilChange,
        defaultMileageInterval: 5000,
        category: .engine
      ),
      ServiceTemplate(
        id: "template_oil_filter_change",
        name: .oilFilterChange,
        defaultMileageInterval: 5000,
        category: .engine
      ),
      ServiceTemplate(
        id: "template_air_filter_change",
        name: .airFilterChange,
        defaultMileageInterval: 12000,
        category: .engine
      ),
      ServiceTemplate(
        id: "template_spark_plugs_change",
        name: .sparkPlugsChange,
        defaultMileageInterval: 12000,
        category: .engine
      ),
      ServiceTemplate(
        id: "template_valve_adjustment",
        name: .valveAdjustment,
        defaultMileageInterval: 6000,
        category: .engine
      ),
      
      // Трансмиссия
      ServiceTemplate(
        id: "template_chain_lubrication",
        name: .chainLubrication,
        defaultMileageInterval: 500,
        category: .transmission
      ),
      ServiceTemplate(
        id: "template_chain_replacement",
        name: .chainReplacement,
        defaultMileageInterval: 30000,
        category: .transmission
      ),
      
      // Тормоза
      ServiceTemplate(
        id: "template_brake_pads_change",
        name: .brakePadsChange,
        defaultMileageInterval: 6000, // Проверка каждые 6000 км
        category: .brakes
      ),
      ServiceTemplate(
        id: "template_brake_fluid_change",
        name: .brakeFluidChange,
        defaultTimeInterval: 730, // 2 года
        category: .brakes
      ),
      
      // Охлаждение
      ServiceTemplate(
        id: "template_coolant_change",
        name: .coolantChange,
        defaultTimeInterval: 1095, // 3 года
        category: .cooling
      )
    ]
  }
  
  /// Получить шаблон по ID
  static func template(id: String) -> ServiceTemplate? {
    allTemplates.first { $0.id == id }
  }
  
  /// Получить шаблон по имени
  static func template(name: Name) -> ServiceTemplate? {
    allTemplates.first { $0.name == name }
  }
}
