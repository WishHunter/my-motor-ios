import Foundation
import Factory
import Combine

/// Кастомный интервал для шаблона (по пробегу и/или времени)
public struct CustomServiceInterval: Codable, Hashable {
  public var mileageInterval: Int?
  public var timeInterval: Int? // дни
  
  public init(mileageInterval: Int? = nil, timeInterval: Int? = nil) {
    self.mileageInterval = mileageInterval
    self.timeInterval = timeInterval
  }
}

public extension Container {
  var serviceSession: Factory<ServiceSession> {
    self { ServiceSession() }.singleton
  }
}

/// Хранилище истории обслуживания мотоциклов
public final class ServiceSession: ObservableObject {
  @Published(wrappedValue: [], key: "saved_service")
  public private(set) var services: [ServiceInfo]
  
  /// Кастомные интервалы по ключу "motorId_templateId" (для галочки "сохранить для всех будущих замен")
  @Published(wrappedValue: [:], key: "custom_service_intervals")
  public private(set) var customServiceIntervals: [String: CustomServiceInterval]

  /// Добавляет запись о сервисе
  public func add(_ service: ServiceInfo) {
    services.append(service)
  }
  
  /// Получает все сервисы для конкретного мотоцикла
  public func services(for motorId: String) -> [ServiceInfo] {
    services.filter { $0.motorId == motorId }
  }
  
  /// Удаляет сервис по ID
  public func remove(id: String) {
    services.removeAll { $0.id == id }
  }
  
  /// Обновляет существующий сервис
  public func update(_ service: ServiceInfo) {
    guard let index = services.firstIndex(where: { $0.id == service.id }) else { return }
    services[index] = service
  }
  
  /// Удаляет все сервисы для конкретного мотоцикла
  public func removeAll(for motorId: String) {
    services.removeAll { $0.motorId == motorId }
  }
  
  /// Ключ для кастомного интервала
  public static func customIntervalKey(motorId: String, templateId: String) -> String {
    "\(motorId)_\(templateId)"
  }
  
  /// Получить кастомный интервал для мотоцикла и шаблона
  public func customInterval(motorId: String, templateId: String) -> CustomServiceInterval? {
    customServiceIntervals[Self.customIntervalKey(motorId: motorId, templateId: templateId)]
  }
  
  /// Сохранить кастомный интервал для всех будущих замен
  public func setCustomInterval(motorId: String, templateId: String, mileageInterval: Int?, timeInterval: Int?) {
    let key = Self.customIntervalKey(motorId: motorId, templateId: templateId)
    var next = customServiceIntervals
    if mileageInterval != nil || timeInterval != nil {
      next[key] = CustomServiceInterval(mileageInterval: mileageInterval, timeInterval: timeInterval)
    } else {
      next.removeValue(forKey: key)
    }
    customServiceIntervals = next
  }
}
