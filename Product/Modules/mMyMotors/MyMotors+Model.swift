import Foundation
import Combine
import Factory
import SwiftUI

/// Модель для управления экраном "Мои мотоциклы"
final class MyMotorsModel: ObservableObject {
  @Injected(\.motorsSession) var motorsSession: MotorsSession
  
  // MARK: - Published Properties
  @Published var isAddMotorSheetPresented = false
  @Published var selectedMotorId: String?
  @Published private var currentMainMotorId: String?
  
  // MARK: - Computed Properties
  var motors: [MotorInfo] {
    motorsSession.motors
  }
  
  var isEmpty: Bool {
    motorsSession.motors.isEmpty
  }
  
  var mainMotor: MotorInfo? {
    motorsSession.mainMotor
  }
  
  // MARK: - Initialization
  init() {
    // Инициализируем currentMainMotorId
    currentMainMotorId = motorsSession.mainMotor?.id
    
    // Подписываемся на изменения в сессии для обновления UI
    motorsSession.$motors
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.objectWillChange.send()
      }
      .store(in: &cancellables)
    
    motorsSession.$mainMotor
      .receive(on: DispatchQueue.main)
      .sink { [weak self] mainMotor in
        self?.currentMainMotorId = mainMotor?.id
        self?.objectWillChange.send()
      }
      .store(in: &cancellables)
  }
  
  private var cancellables = Set<AnyCancellable>()
  
  // MARK: - Public Methods
  
  /// Проверяет, является ли мотоцикл главным
  func isMainMotor(_ motor: MotorInfo) -> Bool {
    motorsSession.mainMotor?.id == motor.id
  }
  
  /// Устанавливает главный мотоцикл
  @MainActor
  func setMainMotor(_ motor: MotorInfo) {
    motorsSession.setMainMotor(id: motor.id)
  }
  
  /// Устанавливает главный мотоцикл по ID
  @MainActor
  func setMainMotor(id: String) {
    motorsSession.setMainMotor(id: id)
  }
  
  /// Обрабатывает тап по карточке мотоцикла
  @MainActor
  func handleMotorTap(_ motor: MotorInfo) {
    // Если это уже главный мотоцикл, ничего не делаем
    guard !isMainMotor(motor) else { return }
    
    // Сначала обновляем selectedMotorId для немедленной визуальной обратной связи
    selectedMotorId = motor.id
    
    // Устанавливаем новый главный мотоцикл
    setMainMotor(motor)
  }
  
  /// Показывает экран добавления мотоцикла
  @MainActor
  func showAddMotorSheet() {
    isAddMotorSheetPresented = true
  }
  
  /// Скрывает экран добавления мотоцикла
  @MainActor
  func hideAddMotorSheet() {
    isAddMotorSheetPresented = false
  }
  
  /// Удаляет мотоцикл
  func removeMotor(_ motor: MotorInfo) {
    motorsSession.remove(id: motor.id)
  }
}
