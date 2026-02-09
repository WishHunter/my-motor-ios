import Foundation
import Factory
import Combine

public extension Container {
  var serviceSession: Factory<ServiceSession> {
    self { ServiceSession() }.singleton
  }
}

/// Хранилище истории обслуживания мотоциклов
public final class ServiceSession: ObservableObject {
  @Published(wrappedValue: [], key: "saved_service")
  public private(set) var services: [ServiceInfo]

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
}
