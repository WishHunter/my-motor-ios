import SwiftUI
import Factory

@MainActor
final class AddServiceModel: ObservableObject {
  @Injected(\.serviceSession) var serviceSession: ServiceSession
  @Injected(\.motorsSession) var motorsSession: MotorsSession

  // Идентификатор редактируемой записи. Nil означает создание новой.
  private var editingServiceId: String?

  // Поля формы.
  @Published var type: ServiceInfo.ServiceType = .service
  @Published var name: String = ""
  @Published var typePetrol: ServiceInfo.PetrolType = .petrol95
  @Published var date: Date = Date()
  @Published var mileageText: String = ""
  @Published var priceText: String = ""
  @Published var fuelVolumeText: String = ""
  @Published var selectedTemplateId: String? = nil
  @Published var customMileageIntervalText: String = ""
  @Published var customTimeIntervalText: String = ""
  @Published var saveIntervalForFuture: Bool = false
  
  var isEditing: Bool {
    editingServiceId != nil
  }

  private var currentMotorId: String? {
    motorsSession.mainMotor?.id
  }

  private var currentMotorServicesSortedByDateDesc: [ServiceInfo] {
    guard let motorId = currentMotorId else { return [] }
    return serviceSession.services(for: motorId)
      .sorted { lhs, rhs in
        if lhs.date != rhs.date { return lhs.date > rhs.date }
        return lhs.id > rhs.id
      }
  }

  private var editingIndexInCurrentMotorServices: Int? {
    guard let id = editingServiceId else { return nil }
    return currentMotorServicesSortedByDateDesc.firstIndex(where: { $0.id == id })
  }

  // Является ли редактируемая запись последней (самой новой) по дате для текущего мотоцикла.
  var isEditingMostRecent: Bool {
    guard isEditing, let idx = editingIndexInCurrentMotorServices else { return false }
    return idx == 0
  }

  // Можно ли редактировать дату (создание или редактирование последней записи).
  var isDateEditable: Bool {
    !isEditing || isEditingMostRecent
  }

  private struct MileageBounds: Equatable {
    var min: Int?
    var max: Int?
  }

  private var mileageBounds: MileageBounds {
    let servicesDesc = currentMotorServicesSortedByDateDesc

    // Редактирование. Границы определяются соседями в списке (по дате по убыванию).
    if let idx = editingIndexInCurrentMotorServices {
      if idx == 0 {
        // Последняя запись. Пробег не ниже предыдущей записи (если она есть).
        let prev = servicesDesc.dropFirst().first
        return MileageBounds(min: prev?.mileage, max: nil)
      } else {
        // Не последняя запись. Пробег в диапазоне между более новой и более старой записью.
        let newer = servicesDesc[safe: idx - 1]
        let older = servicesDesc[safe: idx + 1]
        return MileageBounds(min: older?.mileage, max: newer?.mileage)
      }
    }

    // Создание. Ограничиваем пробег по соседям по дате, если запись вставляется в середину истории.
    let asc = servicesDesc.reversed()
    let newer = asc.first(where: { $0.date > date })
    let older = asc.last(where: { $0.date < date })
    return MileageBounds(min: older?.mileage, max: newer?.mileage)
  }

  var mileageInvalidText: String {
    let base = "Введите корректный пробег"
    let hardRange = "0–2 000 000 км"
    guard mileageBounds.min != nil || mileageBounds.max != nil else {
      return "\(base) (\(hardRange))"
    }
    if let min = mileageBounds.min, let max = mileageBounds.max {
      return "\(base) (\(min)–\(max) км)"
    }
    if let min = mileageBounds.min {
      return "\(base) (от \(min) км)"
    }
    if let max = mileageBounds.max {
      return "\(base) (до \(max) км)"
    }
    return "\(base) (\(hardRange))"
  }

  private var minimumAllowedDateForMostRecentEdit: Date? {
    guard isEditingMostRecent else { return nil }
    return currentMotorServicesSortedByDateDesc.dropFirst().first?.date
  }

  // Валидация.
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
    guard m >= 0 && m <= 2_000_000 else { return false }
    let bounds = mileageBounds
    if let min = bounds.min, m < min { return false }
    if let max = bounds.max, m > max { return false }
    return true
  }

  var isPriceValid: Bool {
    guard let p = price else { return false }
    return p >= 0 && p <= 10_000_000
  }

  var isFuelVolumeValid: Bool {
    guard let v = fuelVolume else { return false }
    return v >= 0 && v <= 200
  }

  var isSaveDisabled: Bool {
    if !isMileageValid || !isPriceValid { return true }
    if isNameRequired && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
    if isFuelVolumeRequired && !isFuelVolumeValid { return true }
    return false
  }

  enum SaveError: LocalizedError, Identifiable, Equatable {
    case invalidForm
    case noMainMotor
    case missingFuelVolume
    case invalidDate

    var id: String { localizedDescription }

    var errorDescription: String? {
      switch self {
      case .invalidForm:
        return "Проверьте введённые данные."
      case .noMainMotor:
        return "Не выбран основной мотоцикл."
      case .missingFuelVolume:
        return "Укажите объём заправки."
      case .invalidDate:
        return "Дата не может быть раньше предыдущей записи."
      }
    }
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

  @discardableResult
  func save() -> Result<Void, SaveError> {
    guard !isSaveDisabled, let mileage = mileage, let price = price else { return .failure(.invalidForm) }
    guard let motor = motorsSession.mainMotor else { return .failure(.noMainMotor) }
    let motorId = motor.id

    if isEditingMostRecent, let minDate = minimumAllowedDateForMostRecentEdit, date < minDate {
      return .failure(.invalidDate)
    }

    if isFuelVolumeRequired, fuelVolume == nil {
      return .failure(.missingFuelVolume)
    }

    // Интервалы для сохранения в ServiceInfo.
    let serviceCustomMileageInterval: Int?
    let serviceCustomTimeInterval: Int?
    
    let templateIdToSave: String? = (type == .service) ? selectedTemplateId : nil

    if templateIdToSave != nil {
      serviceCustomMileageInterval = customMileageInterval ?? selectedTemplate?.defaultMileageInterval
      serviceCustomTimeInterval = customTimeInterval ?? selectedTemplate?.defaultTimeInterval
    } else {
      serviceCustomMileageInterval = nil
      serviceCustomTimeInterval = nil
    }

    let service: ServiceInfo
    if let editingId = editingServiceId {
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
        templateId: templateIdToSave,
        customMileageInterval: serviceCustomMileageInterval,
        customTimeInterval: serviceCustomTimeInterval
      )
      serviceSession.update(service)
    } else {
      service = ServiceInfo(
        motorId: motorId,
        type: type,
        name: isNameRequired ? name.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
        typePetrol: isPetrolRequired ? typePetrol : nil,
        date: date,
        mileage: mileage,
        price: price,
        fuelVolume: isFuelVolumeRequired ? fuelVolume : nil,
        templateId: templateIdToSave,
        customMileageInterval: serviceCustomMileageInterval,
        customTimeInterval: serviceCustomTimeInterval
      )
      serviceSession.add(service)
    }

    // Правила обновления пробега мотоцикла.
    // Редактирование последней записи: переписываем пробег до неё.
    // Редактирование не последней записи: пробег не меняем.
    // Создание: обновляем пробег только если запись становится последней по дате.
    let shouldUpdateMotorMileage: Bool
    if isEditing {
      shouldUpdateMotorMileage = isEditingMostRecent
    } else {
      let mostRecentOtherDate = currentMotorServicesSortedByDateDesc.first?.date
      shouldUpdateMotorMileage = (mostRecentOtherDate == nil) || (date >= mostRecentOtherDate!)
    }
    if shouldUpdateMotorMileage {
      motorsSession.updateMileage(mileage)
    }
    
    if type == .service, let templateId = selectedTemplateId, saveIntervalForFuture {
      let m = customMileageInterval ?? selectedTemplate?.defaultMileageInterval
      let t = customTimeInterval ?? selectedTemplate?.defaultTimeInterval
      serviceSession.setCustomInterval(motorId: motorId, templateId: templateId, mileageInterval: m, timeInterval: t)
    }
    resetForm()
    return .success(())
  }

  func resetForm() {
    editingServiceId = nil
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
  
  // Выбрать шаблон и автоматически заполнить название.
  func selectTemplate(_ template: ServiceTemplate) {
    selectedTemplateId = template.id
    name = template.name.displayName
    
    if let motorId = motorsSession.mainMotor?.id,
       let custom = serviceSession.customInterval(motorId: motorId, templateId: template.id) {
      customMileageIntervalText = custom.mileageInterval.map { "\($0)" } ?? ""
      customTimeIntervalText = custom.timeInterval.map { "\($0)" } ?? ""
      saveIntervalForFuture = true
    } else {
      customMileageIntervalText = ""
      customTimeIntervalText = ""
      saveIntervalForFuture = false
    }
  }

  func clearTemplateSelection() {
    selectedTemplateId = nil
    customMileageIntervalText = ""
    customTimeIntervalText = ""
    saveIntervalForFuture = false
  }
  
  // Получить выбранный шаблон.
  var selectedTemplate: ServiceTemplate? {
    guard let templateId = selectedTemplateId else { return nil }
    return ServiceTemplate.template(id: templateId)
  }
}

private extension Array {
  subscript(safe index: Int) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
