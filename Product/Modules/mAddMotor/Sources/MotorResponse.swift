public struct MotorResponse: Identifiable, Codable, Hashable {
  public var id: String
  public var brandId: String
  public var name: String
  public var segment: Segment?
  public var production: ProductionPeriod?
  public var notes: String?
  public var periodSpecs: [PeriodSpec]

  static let empty: Self = .init(id: "", brandId: "", name: "Выбери модель, раб", periodSpecs: [])
}

public enum Segment: String, Codable, CaseIterable {
  case sport, naked, adventure, touring, cruiser, scooter, offroad, dualsport, retro, electric, motard, classic, scrambler, enduro, commuter, sidecar, other
  case sportTouring = "sport-touring"
  case powerCruiser = "power-cruiser"
  case retroScooter = "retro-scooter"
}

public struct ProductionPeriod: Codable, Hashable {
  public var startYear: Int
  public var endYear: Int?
}

public struct PeriodSpec: Identifiable, Codable, Hashable {
  public var id: String
  public var startYear: Int
  public var endYear: Int?
  public var revision: String?
  public var engine: EngineSpec?
  public var transmission: TransmissionSpec?
  public var chassis: ChassisSpec?
  public var dimensions: DimensionSpec?
  public var equipment: EquipmentSpec?
}

public struct EngineSpec: Codable, Hashable {
  public var displacementCC: Double?
  public var engineType: String?
  public var powerHP: Double?
  public var powerKW: Double?
  public var torqueNm: Double?
  public var coolingSystem: String?
  public var starter: String?
  public var emissionStandard: String?
}

public struct TransmissionSpec: Codable, Hashable {
  public var gearbox: String?
  public var finalDrive: String?
  public var clutch: String?
  public var transmissionType: String?
}

public struct ChassisSpec: Codable, Hashable {
  public var frontSuspension: String?
  public var rearSuspension: String?
  public var frontWheelTravelMM: Double?
  public var rearWheelTravelMM: Double?
  public var frontTire: String?
  public var rearTire: String?
  public var frontBrake: String?
  public var rearBrake: String?
  public var abs: String?
}

public struct DimensionSpec: Codable, Hashable {
  public var totalWeightKG: Double?
  public var seatHeightMM: Double?
  public var totalLengthMM: Double?
  public var totalHeightMM: Double?
  public var totalWidthMM: Double?
  public var wheelbaseMM: Double?
  public var groundClearanceMM: Double?
  public var fuelCapacityL: Double?
}

public struct EquipmentSpec: Codable, Hashable {
  public var lighting: String?
  public var dash: String?
  public var electronics: [String]?
  public var notes: String?
}
