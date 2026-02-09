public struct BrandResponse: Identifiable, Codable, Hashable {
  public var id: String
  public var name: String
  public var country: Country

  public enum Country: String, Codable, CaseIterable {
      case japan, italy, germany, usa, uk, india, china, austria, sweden, czech, france, spain, taiwan, russia, other
  }

  static let empty: Self = .init(id: "", name: "Выбери бренд, раб", country: .other)
}
