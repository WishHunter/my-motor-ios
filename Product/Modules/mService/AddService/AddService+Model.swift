import SwiftUI
import Factory

final class AddServiceModel: ObservableObject {
  @Injected(\.serviceSession) var serviceSession: ServiceSession
  @Injected(\.motorsSession) var motorsSession: MotorsSession

  // ID редактируемой записи (nil если создание новой)
  private var editingServiceId: String?

  // Поля формы
  @Published var type: ServiceInfo.ServiceType = .service
  @Published var name: String = ""
  @Published var typePetrol: ServiceInfo.PetrolType = .petrol95
  @Published var date: Date = Date()
  @Published var mileageText: String = ""
  @Published var priceText: String = ""
  @Published var fuelVolumeText: String = "" // объем заправки в литрах (текст)
  
  var isEditing: Bool {
    editingServiceId != nil
  }

  // Валидация
  var mileage: Int? {
    Int(mileageText.filter { $0.isNumber })
  }

  var price: Double? {
    let normalized = priceText.replacingOccurrences(of: ",", with: ".")
    return Double(normalized)
  }

  var fuelVolume: Double? {
    let normalized = fuelVolumeText.replacingOccurrences(of: ",", with: ".")
    return Double(normalized)
  }

  var isNameRequired: Bool {
    type == .service
  }

  var isPetrolRequired: Bool {
    type == .refuelling
  }

  var isFuelVolumeRequired: Bool {
    type == .refuelling
  }

  var isMileageValid: Bool {
    guard let m = mileage else { return false }
    // При редактировании не проверяем, что пробег больше текущего (старая запись может иметь меньший пробег)
    if !isEditing {
      guard motorsSession.mainMotor?.mileage ?? 0 <= m else { return false }
    }
    return m >= 0 && m <= 2_000_000
  }

  var isPriceValid: Bool {
    guard let p = price else { return false }
    return p >= 0 && p <= 10_000_000
  }

  var isFuelVolumeValid: Bool {
    // Разумные пределы объема бака/заправки
    guard let v = fuelVolume else { return false }
    return v >= 0 && v <= 200
  }

  var isSaveDisabled: Bool {
    if !isMileageValid || !isPriceValid { return true }
    if isNameRequired && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
    if isFuelVolumeRequired && !isFuelVolumeValid { return true }
    return false
  }

  init(editingService: ServiceInfo? = nil) {
    if let service = editingService {
      loadFromService(service)
    }
  }
  
  func loadFromService(_ service: ServiceInfo) {
    editingServiceId = service.id
    type = service.type
    name = service.name ?? ""
    typePetrol = service.typePetrol ?? .petrol95
    date = service.date
    mileageText = "\(service.mileage)"
    priceText = String(format: "%.0f", service.price)
    fuelVolumeText = service.fuelVolume.map { String(format: "%.2f", $0) } ?? ""
  }

  func save() {
    guard let mileage = mileage, let price = price else { return }
    guard let motorId = motorsSession.mainMotor?.id else { return }

    let service: ServiceInfo
    if let editingId = editingServiceId {
      // Редактирование существующей записи
      service = ServiceInfo(
        id: editingId,
        motorId: motorId,
        type: type,
        name: isNameRequired ? name.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
        typePetrol: isPetrolRequired ? typePetrol : nil,
        date: date,
        mileage: mileage,
        price: price,
        fuelVolume: isFuelVolumeRequired ? fuelVolume : nil
      )
      serviceSession.update(service)
    } else {
      // Создание новой записи
      service = ServiceInfo(
        motorId: motorId,
        type: type,
        name: isNameRequired ? name.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
        typePetrol: isPetrolRequired ? typePetrol : nil,
        date: date,
        mileage: mileage,
        price: price,
        fuelVolume: isFuelVolumeRequired ? fuelVolume : nil
      )
      serviceSession.add(service)
    }
    motorsSession.updateMileage(mileage)
    resetForm()
  }

  func resetForm() {
    switch type {
    case .service:
      name = ""
    case .refuelling:
      typePetrol = .petrol95
      fuelVolumeText = ""
    }
    date = Date()
    mileageText = ""
    priceText = ""
  }
}
