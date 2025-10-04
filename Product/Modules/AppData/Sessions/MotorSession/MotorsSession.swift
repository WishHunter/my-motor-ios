import Foundation
import Factory
import Combine

public extension Container {
  var motorsSession: Factory<MotorsSession> {
    self { MotorsSession() }.singleton
  }
}

/// Простое хранилище мотоциклов пользователя
public final class MotorsSession: ObservableObject {
  @Published(wrappedValue: [], key: "saved_motors")
  public private(set) var motors: [MotorInfo]
  
  @Published(wrappedValue: nil, key: "main_motor")
  public private(set) var mainMotor: MotorInfo?

  /// Добавляет мотоцикл
  public func add(_ motor: MotorInfo) {
    motors.append(motor)

    if mainMotor == nil {
      mainMotor = motor
    }
  }
  
  /// Удаляет мотоцикл по ID
  public func remove(id: String) {
    motors.removeAll(where: { $0.id == id })

    if mainMotor?.id == id {
      if let nextMotor = motors.first {
        setMainMotor(id: nextMotor.id)
      } else {
        mainMotor = nil
      }
    }
  }
  
  /// Очищает все мотоциклы
  public func clear() {
    motors = []
    mainMotor = nil
  }
  
  /// Получает мотоцикл по ID
  public func motor(id: String) -> MotorInfo? {
    motors.first { $0.id == id }
  }

  /// Устанавливает основной мотоцикл по ID
  public func setMainMotor(id: String) {
    if let motor = motor(id: id) {
      mainMotor = motor
    }
  }
  
  /// Проверяет, является ли мотоцикл основным
  public func isMainMotor(_ motor: MotorInfo) -> Bool {
    mainMotor?.id == motor.id
  }
}
