import Foundation

public struct MotorInfo: Codable, Identifiable, Hashable {
  public var id: String
  public var make: String
  public var model: String
  public var year: Int
  public var mileage: Int
  public var info: ModelInfo
  
  public init(id: String = UUID().uuidString, make: String, model: String, year: Int, mileage: Int, info: ModelInfo) {
    self.id = id
    self.make = make
    self.model = model
    self.year = year
    self.mileage = mileage
    self.info = info
  }

  public struct ModelInfo: Codable, Hashable {
    public var displacement: Double
    public var engineType: EngineType
    public var power: Int
    public var torque: Int
    public var coolingSystem: CoolingSystem
    public var gearbox: Gearbox
    public var transmission: TransmissionType
    public var frontSuspension: SuspensionType
    public var rearSuspension: SuspensionType
    public var frontWheelTravel: Double
    public var rearWheelTravel: Double
    public var frontTire: String
    public var rearTire: String
    public var frontBrake: BrakeType
    public var rearBrake: BrakeType
    public var totalWeight: Double
    public var seatHeight: Double
    public var totalLength: Double
    public var totalHeight: Double
    public var totalWidth: Double
    public var wheelbase: Double
    public var groundClearance: Double
    public var fuelCapacity: Double
    public var starter: StarterType
  }
}

// MARK: - Engine Types
public enum EngineType: String, Codable, CaseIterable {
  case single = "Single"
  case parallelTwin = "Parallel Twin"
  case inline4 = "Inline-4"
  case vTwin = "V-Twin"
  case vTwinTestastretta = "V-Twin Testastretta"
  case vTwinTestastrettaDVT = "V-Twin Testastretta DVT"
  case v4 = "V4"
  case v4Granturismo = "V4 Granturismo"
  case flat6 = "Flat-6"
  case boxer = "Boxer"
  case triple = "Triple"
  case inline3 = "Inline-3"
  case unknown = "Unknown"
}

// MARK: - Cooling Systems
public enum CoolingSystem: String, Codable, CaseIterable {
  case liquid = "Liquid"
  case air = "Air"
  case oil = "Oil"
  case unknown = "Unknown"
}

// MARK: - Gearbox Types
public enum Gearbox: String, Codable, CaseIterable {
  case speed4 = "4-speed"
  case speed5 = "5-speed"
  case speed6 = "6-speed"
  case speed7 = "7-speed"
  case cvt = "CVT"
  case automatic = "Automatic"
  case unknown = "Unknown"
}

// MARK: - Transmission Types
public enum TransmissionType: String, Codable, CaseIterable {
  case manual = "Manual"
  case dct = "DCT"
  case automatic = "Automatic"
  case semiAutomatic = "Semi-Automatic"
  case unknown = "Unknown"
}

// MARK: - Suspension Types
public enum SuspensionType: String, Codable, CaseIterable {
  case usd = "USD"
  case showaUSD = "Showa USD"
  case telescopic = "Telescopic"
  case conventional = "Conventional"
  case monoshock = "Monoshock"
  case dualShock = "Dual Shock"
  case unknown = "Unknown"
  
  // Computed property for display
  public var displayName: String {
    switch self {
    case .usd: return "USD"
    case .showaUSD: return "Showa USD"
    case .telescopic: return "Telescopic"
    case .conventional: return "Conventional"
    case .monoshock: return "Monoshock"
    case .dualShock: return "Dual Shock"
    case .unknown: return "Unknown"
    }
  }
}

// MARK: - Brake Types
public enum BrakeType: String, Codable, CaseIterable {
  case disc = "Disc"
  case dualDisc = "Dual Disc"
  case singleDisc = "Single Disc"
  case drum = "Drum"
  case abs = "ABS"
  case combined = "Combined"
  case unknown = "Unknown"
}

// MARK: - Starter Types
public enum StarterType: String, Codable, CaseIterable {
  case electric = "Electric"
  case kick = "Kick"
  case electricKick = "Electric/Kick"
  case unknown = "Unknown"
}
