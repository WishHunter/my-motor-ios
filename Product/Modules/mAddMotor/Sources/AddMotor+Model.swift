import SwiftUI
import Factory

final class AddMotorModel: ObservableObject {
  @Injected(\.motorsSession) private var motorsSession

  @Published var brands: [BrandResponse] = []
  @Published var models: [MotorResponse] = []
  @Published var years: [Int] = []
  @Published var isLoading: Bool = false

  @Published var selectedBrand: BrandResponse? = nil
  @Published var selectedModel: MotorResponse? = nil
  @Published var selectedYear: Int? = nil
  @Published var mileage: String = ""

  var isContinueDisabled: Bool {
    isLoading || selectedBrand?.id.isEmpty != false || selectedModel?.id.isEmpty != false || selectedYear == nil || mileage.isEmpty || !isValidMileage
  }

  var isValidMileage: Bool {
    guard let mileageInt = Int(mileage) else { return false }
    return mileageInt >= 0 && mileageInt <= 999999 // Разумные пределы для пробега
  }

  init() {
    Task { await getBrands() }
  }

  @MainActor
  private func getBrands() async {
    isLoading = true
    brands = await Bundle.main.load("brands", as: [BrandResponse].self, default: [])
    isLoading = false
  }

  @MainActor
  func getModels(forBrandWithId brandId: String) async {
    isLoading = true
    models = await Bundle.main.load("models_\(brandId)", as: [MotorResponse].self, default: [])
    if !models.isEmpty {
      getYears()
    }
    isLoading = false
  }

  func getYears() {
    years = []
    guard let selectedModel = selectedModel else {
      selectedYear = nil
      return
    }
    let startYear: Int = selectedModel.production?.startYear ?? Calendar.current.component(.year, from: Date())
    let endYear: Int = selectedModel.production?.endYear ?? Calendar.current.component(.year, from: Date())
    years = Array(startYear...endYear)
  }

  func saveMotor() {
    guard let mileageInt = Int(mileage) else {
      print("Ошибка: некорректный пробег")
      return
    }
    
    guard let selectedBrand = selectedBrand,
          let selectedModel = selectedModel,
          let selectedYear = selectedYear else {
      print("Ошибка: не все поля выбраны")
      return
    }

    guard let motorInfo = MotorInfo(
      brand: selectedBrand,
      model: selectedModel,
      year: selectedYear,
      mileage: mileageInt
    ) else {
      print("Ошибка создания MotorInfo")
      return
    }

    motorsSession.add(motorInfo)
  }
}

// MARK: - Private Extension for MotorInfo Creation
private extension MotorInfo {
  init?(
    brand: BrandResponse,
    model: MotorResponse,
    year: Int,
    mileage: Int
  ) {
    // Находим спецификации для выбранного года
    guard let periodSpec = MotorInfo.findPeriodSpec(for: year, in: model.periodSpecs) else {
      return nil
    }
    
    self.init(
      make: brand.name,
      model: model.name,
      year: year,
      mileage: mileage,
      info: ModelInfo(
        displacement: periodSpec.engine?.displacementCC ?? 0.0,
        engineType: EngineType(rawValue: periodSpec.engine?.engineType ?? "") ?? .unknown,
        power: Int(periodSpec.engine?.powerHP ?? 0),
        torque: Int(periodSpec.engine?.torqueNm ?? 0),
        coolingSystem: CoolingSystem(rawValue: periodSpec.engine?.coolingSystem ?? "") ?? .unknown,
        gearbox: Gearbox(rawValue: periodSpec.transmission?.gearbox ?? "") ?? .unknown,
        transmission: TransmissionType(rawValue: periodSpec.transmission?.transmissionType ?? "") ?? .unknown,
        frontSuspension: MotorInfo.parseSuspensionType(periodSpec.chassis?.frontSuspension),
        rearSuspension: MotorInfo.parseSuspensionType(periodSpec.chassis?.rearSuspension),
        frontWheelTravel: periodSpec.chassis?.frontWheelTravelMM ?? 0.0,
        rearWheelTravel: periodSpec.chassis?.rearWheelTravelMM ?? 0.0,
        frontTire: periodSpec.chassis?.frontTire ?? "Unknown",
        rearTire: periodSpec.chassis?.rearTire ?? "Unknown",
        frontBrake: BrakeType(rawValue: periodSpec.chassis?.frontBrake ?? "") ?? .unknown,
        rearBrake: BrakeType(rawValue: periodSpec.chassis?.rearBrake ?? "") ?? .unknown,
        totalWeight: periodSpec.dimensions?.totalWeightKG ?? 0.0,
        seatHeight: periodSpec.dimensions?.seatHeightMM ?? 0.0,
        totalLength: periodSpec.dimensions?.totalLengthMM ?? 0.0,
        totalHeight: periodSpec.dimensions?.totalHeightMM ?? 0.0,
        totalWidth: periodSpec.dimensions?.totalWidthMM ?? 0.0,
        wheelbase: periodSpec.dimensions?.wheelbaseMM ?? 0.0,
        groundClearance: periodSpec.dimensions?.groundClearanceMM ?? 0.0,
        fuelCapacity: periodSpec.dimensions?.fuelCapacityL ?? 0.0,
        starter: StarterType(rawValue: periodSpec.engine?.starter ?? "") ?? .unknown
      )
    )
  }
  
  private static func findPeriodSpec(for year: Int, in specs: [PeriodSpec]) -> PeriodSpec? {
    return specs.first { spec in
      let startYear = spec.startYear
      let endYear = spec.endYear ?? Int.max
      return year >= startYear && year <= endYear
    }
  }
  
  private static func parseSuspensionType(_ suspensionString: String?) -> SuspensionType {
    guard let suspension = suspensionString else { return .unknown }
    
    // Парсим различные варианты подвески из JSON
    if suspension.contains("USD") {
      if suspension.contains("Showa") {
        return .showaUSD
      }
      return .usd
    } else if suspension.contains("Telescopic") {
      return .telescopic
    } else if suspension.contains("Conventional") {
      return .conventional
    } else if suspension.contains("Monoshock") {
      return .monoshock
    } else if suspension.contains("Dual") {
      return .dualShock
    }
    
    return .unknown
  }
}
