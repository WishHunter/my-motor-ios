import Foundation
import Combine
import Factory
import SwiftUI

final class MyMotorsModel: ObservableObject {
  @Injected(\.motorsSession) var motorsSession: MotorsSession
  
  @Published var isAddMotorSheetPresented = false
  @Published var selectedMotorId: String?
  @Published private var currentMainMotorId: String?
  
  var motors: [MotorInfo] {
    motorsSession.motors
  }
  
  var isEmpty: Bool {
    motorsSession.motors.isEmpty
  }
  
  var mainMotor: MotorInfo? {
    motorsSession.mainMotor
  }
  
  init() {
    currentMainMotorId = motorsSession.mainMotor?.id
    
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
  
  // Проверяет, является ли мотоцикл главным.
  func isMainMotor(_ motor: MotorInfo) -> Bool {
    motorsSession.mainMotor?.id == motor.id
  }
  
  @MainActor
  func setMainMotor(_ motor: MotorInfo) {
    motorsSession.setMainMotor(id: motor.id)
  }
  
  @MainActor
  func setMainMotor(id: String) {
    motorsSession.setMainMotor(id: id)
  }
  
  @MainActor
  func handleMotorTap(_ motor: MotorInfo) {
    guard !isMainMotor(motor) else { return }
    
    selectedMotorId = motor.id
    
    setMainMotor(motor)
  }
  
  @MainActor
  func showAddMotorSheet() {
    isAddMotorSheetPresented = true
  }
  
  @MainActor
  func hideAddMotorSheet() {
    isAddMotorSheetPresented = false
  }
  
  func removeMotor(_ motor: MotorInfo) {
    motorsSession.remove(id: motor.id)
  }
}
