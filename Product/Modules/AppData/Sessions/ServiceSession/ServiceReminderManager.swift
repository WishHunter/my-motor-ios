import Foundation
import Factory

public extension Container {
  var serviceReminderManager: Factory<ServiceReminderManager> {
    self { ServiceReminderManager() }.singleton
  }
}

/// Менеджер для расчета и управления напоминаниями о регулярных сервисах
public final class ServiceReminderManager {
  @Injected(\.serviceSession) private var serviceSession: ServiceSession
  @Injected(\.motorsSession) private var motorsSession: MotorsSession
  
  /// Порог уведомления по пробегу (км)
  private let mileageWarningThreshold: Int = 100
  
  /// Порог уведомления по времени (дни)
  private let timeWarningThresholdDays: Int = 7
  
  public init() {}
  
  /// Информация о предстоящем сервисе
  public struct UpcomingService: Identifiable {
    public let id: String
    public let templateId: String
    public let templateName: String
    public let lastServiceDate: Date?
    public let lastServiceMileage: Int?
    public let nextServiceMileage: Int?
    public let nextServiceDate: Date?
    public let status: Status
    
    public enum Status {
      case onTime // Все в порядке
      case soon // Скоро (за 100 км или за неделю)
      case overdue // Пора (интервал пройден)
    }
  }
  
  /// Получить все предстоящие сервисы для текущего мотоцикла
  public func getUpcomingServices() -> [UpcomingService] {
    guard let motor = motorsSession.mainMotor else { return [] }
    
    let motorServices = serviceSession.services(for: motor.id)
    let templates = ServiceTemplate.allTemplates
    
    var upcomingServices: [UpcomingService] = []
    
    for template in templates {
      // Найти последний сервис с этим шаблоном
      let lastService = motorServices
        .filter { $0.templateId == template.id }
        .sorted { $0.date > $1.date }
        .first
      
      // Интервал: приоритет сохраненному кастомному интервалу (saveIntervalForFuture == true),
      // затем интервалу из последней записи сервиса, затем дефолтному из шаблона
      let savedCustom = serviceSession.customInterval(motorId: motor.id, templateId: template.id)
      let mileageInterval: Int?
      let timeInterval: Int?
      
      if let saved = savedCustom {
        // Используем сохраненный интервал для всех будущих замен
        mileageInterval = saved.mileageInterval ?? template.defaultMileageInterval
        timeInterval = saved.timeInterval ?? template.defaultTimeInterval
      } else if let lastService = lastService {
        // Используем интервал из последней записи (работает только до следующей замены)
        // Если в записи есть кастомный интервал - используем его, иначе дефолтный из шаблона
        mileageInterval = lastService.customMileageInterval ?? template.defaultMileageInterval
        timeInterval = lastService.customTimeInterval ?? template.defaultTimeInterval
      } else {
        // Используем дефолтный из шаблона
        mileageInterval = template.defaultMileageInterval
        timeInterval = template.defaultTimeInterval
      }
      
      // Рассчитать следующий сервис только по последней записи (не от текущего пробега)
      var nextServiceMileage: Int?
      var nextServiceDate: Date?
      
      if let lastService = lastService {
        if let mileageInterval = mileageInterval {
          nextServiceMileage = lastService.mileage + mileageInterval
        }
        if let timeInterval = timeInterval {
          nextServiceDate = Calendar.current.date(byAdding: .day, value: timeInterval, to: lastService.date)
        }
      }
      // Если сервиса ещё не было — не показываем nextServiceMileage/nextServiceDate,
      // иначе при каждом обновлении пробега (заправка) "остаток" не уменьшался бы
      
      // Определить статус
      let status = calculateStatus(
        nextServiceMileage: nextServiceMileage,
        nextServiceDate: nextServiceDate,
        currentMileage: motor.mileage,
        mileageInterval: mileageInterval,
        timeInterval: timeInterval
      )
      
      let upcomingService = UpcomingService(
        id: template.id,
        templateId: template.id,
        templateName: template.name.displayName,
        lastServiceDate: lastService?.date,
        lastServiceMileage: lastService?.mileage,
        nextServiceMileage: nextServiceMileage,
        nextServiceDate: nextServiceDate,
        status: status
      )
      
      upcomingServices.append(upcomingService)
    }
    
    // Сортировка: сначала просроченные, потом скоро, потом в порядке
    return upcomingServices.sorted { service1, service2 in
      switch (service1.status, service2.status) {
      case (.overdue, _): return true
      case (_, .overdue): return false
      case (.soon, _): return true
      case (_, .soon): return false
      default: return false
      }
    }
  }
  
  /// Рассчитать статус предстоящего сервиса
  private func calculateStatus(
    nextServiceMileage: Int?,
    nextServiceDate: Date?,
    currentMileage: Int,
    mileageInterval: Int?,
    timeInterval: Int?
  ) -> UpcomingService.Status {
    var isOverdue = false
    var isSoon = false
    
    // Проверка по пробегу
    if let nextServiceMileage = nextServiceMileage {
      let remainingMileage = nextServiceMileage - currentMileage
      
      if remainingMileage <= 0 {
        isOverdue = true
      } else if remainingMileage <= mileageWarningThreshold {
        isSoon = true
      }
    }
    
    // Проверка по времени
    if let nextServiceDate = nextServiceDate {
      let calendar = Calendar.current
      let now = Date()
      
      if nextServiceDate <= now {
        isOverdue = true
      } else {
        let daysUntilService = calendar.dateComponents([.day], from: now, to: nextServiceDate).day ?? 0
        if daysUntilService <= timeWarningThresholdDays {
          isSoon = true
        }
      }
    }
    
    if isOverdue {
      return .overdue
    } else if isSoon {
      return .soon
    } else {
      return .onTime
    }
  }
  
  /// Получить предстоящие сервисы, требующие внимания (скоро или пора)
  public func getServicesRequiringAttention() -> [UpcomingService] {
    getUpcomingServices().filter { $0.status != .onTime }
  }
}
