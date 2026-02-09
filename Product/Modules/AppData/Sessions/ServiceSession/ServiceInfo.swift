import Foundation

public struct ServiceInfo: Codable, Identifiable, Hashable {
  public var id: String
  public var motorId: String
  public var type: ServiceType
  public var name: String?
  public var typePetrol: PetrolType?
  public var date: Date
  public var mileage: Int
  public var price: Double
  public var fuelVolume: Double?

  init(
    id: String = UUID().uuidString,
    motorId: String,
    type: ServiceType,
    name: String? = nil,
    typePetrol: PetrolType? = nil,
    date: Date,
    mileage: Int,
    price: Double,
    fuelVolume: Double? = nil
  ) {
    self.id = id
    self.motorId = motorId
    self.type = type
    self.name = name
    self.typePetrol = typePetrol
    self.date = date
    self.mileage = mileage
    self.price = price
    self.fuelVolume = fuelVolume
  }

  public enum ServiceType: String, Codable, CaseIterable {
    case service = "Service"
    case refuelling = "Refuelling"
  }

  public enum PetrolType: String, Codable, CaseIterable {
    case diesel = "Diesel"
    case petrol92 = "92"
    case petrol95 = "95"
    case petrol98 = "98"
    case petrol100 = "100"
  }
}
