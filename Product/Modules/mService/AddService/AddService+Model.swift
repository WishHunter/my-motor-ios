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
  @Published var selectedTemplateId: String? = nil // Выбранный шаблон регулярного сервиса
  @Published var customMileageIntervalText: String = "" // переопределение интервала по пробегу (км)
  @Published var customTimeIntervalText: String = "" // переопределение интервала по времени (дни)
  @Published var saveIntervalForFuture: Bool = false // сохранить интервал для всех будущих замен
  
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

  var customMileageInterval: Int? {
    let n = Int(customMileageIntervalText.filter { $0.isNumber })
    return (n ?? 0) > 0 ? n : nil
  }

  var customTimeInterval: Int? {
    let n = Int(customTimeIntervalText.filter { $0.isNumber })
    return (n ?? 0) > 0 ? n : nil
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
    selectedTemplateId = service.templateId
    customMileageIntervalText = service.customMileageInterval.map { "\($0)" } ?? ""
    customTimeIntervalText = service.customTimeInterval.map { "\($0)" } ?? ""
    // Проверяем, сохранен ли этот интервал для будущих замен
    if let templateId = service.templateId,
       let motorId = motorsSession.mainMotor?.id,
       let custom = serviceSession.customInterval(motorId: motorId, templateId: templateId),
       custom.mileageInterval == service.customMileageInterval,
       custom.timeInterval == service.customTimeInterval {
      saveIntervalForFuture = true
    } else {
      saveIntervalForFuture = false
    }
  }

  func save() {
    guard let mileage = mileage, let price = price else { return }
    guard let motorId = motorsSession.mainMotor?.id else { return }

    // Определяем кастомные интервалы для сохранения в ServiceInfo
    // Если есть кастомные интервалы, используем их, иначе nil (будет использован дефолтный из шаблона)
    let serviceCustomMileageInterval: Int?
    let serviceCustomTimeInterval: Int?
    
    if selectedTemplateId != nil {
      // Если указаны кастомные интервалы, сохраняем их
      // Если не указаны, но есть шаблон - используем дефолтные из шаблона для этой записи
      serviceCustomMileageInterval = customMileageInterval ?? selectedTemplate?.defaultMileageInterval
      serviceCustomTimeInterval = customTimeInterval ?? selectedTemplate?.defaultTimeInterval
    } else {
      // Если шаблон не выбран, интервалы не сохраняем
      serviceCustomMileageInterval = nil
      serviceCustomTimeInterval = nil
    }

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
        fuelVolume: isFuelVolumeRequired ? fuelVolume : nil,
        templateId: selectedTemplateId,
        customMileageInterval: serviceCustomMileageInterval,
        customTimeInterval: serviceCustomTimeInterval
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
        fuelVolume: isFuelVolumeRequired ? fuelVolume : nil,
        templateId: selectedTemplateId,
        customMileageInterval: serviceCustomMileageInterval,
        customTimeInterval: serviceCustomTimeInterval
      )
      serviceSession.add(service)
    }
    motorsSession.updateMileage(mileage)
    
    // Если saveIntervalForFuture == true, сохраняем интервалы для всех будущих замен
    if let templateId = selectedTemplateId, saveIntervalForFuture {
      let m = customMileageInterval ?? selectedTemplate?.defaultMileageInterval
      let t = customTimeInterval ?? selectedTemplate?.defaultTimeInterval
      serviceSession.setCustomInterval(motorId: motorId, templateId: templateId, mileageInterval: m, timeInterval: t)
    }
    resetForm()
  }

  func resetForm() {
    switch type {
    case .service:
      name = ""
      selectedTemplateId = nil
      customMileageIntervalText = ""
      customTimeIntervalText = ""
      saveIntervalForFuture = false
    case .refuelling:
      typePetrol = .petrol95
      fuelVolumeText = ""
    }
    date = Date()
    mileageText = ""
    priceText = ""
  }
  
  /// Выбрать шаблон и автоматически заполнить название
  func selectTemplate(_ template: ServiceTemplate) {
    selectedTemplateId = template.id
    name = template.name.displayName
    
    // Загрузить сохраненные кастомные интервалы для этого шаблона, если они есть
    if let motorId = motorsSession.mainMotor?.id,
       let custom = serviceSession.customInterval(motorId: motorId, templateId: template.id) {
      customMileageIntervalText = custom.mileageInterval.map { "\($0)" } ?? ""
      customTimeIntervalText = custom.timeInterval.map { "\($0)" } ?? ""
    } else {
      // Сбросить, если нет сохраненных значений
      customMileageIntervalText = ""
      customTimeIntervalText = ""
    }
  }
  
  /// Получить выбранный шаблон
  var selectedTemplate: ServiceTemplate? {
    guard let templateId = selectedTemplateId else { return nil }
    return ServiceTemplate.allTemplates.first { $0.id == templateId }
  }
}
