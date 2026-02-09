import SwiftUI
import Factory
import Combine

final class ServiceListModel: ObservableObject {
  @Injected(\.serviceSession) var serviceSession: ServiceSession
  @Injected(\.motorsSession) var motorsSession: MotorsSession

  private var cancellables = Set<AnyCancellable>()

  @Published var services: [ServiceInfo] = []

  init() {
    // Подписка на изменения списка сервисов
    serviceSession.$services
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.updateServices()
      }
      .store(in: &cancellables)

    // Подписка на смену главного мотоцикла
    motorsSession.$mainMotor
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.updateServices()
      }
      .store(in: &cancellables)
  }

  private func updateServices() {
    guard let id = motorsSession.mainMotor?.id else {
      self.services = []
      return
    }
    self.services = serviceSession.services
      .filter { $0.motorId == id }
      .sorted { $0.date > $1.date }
  }

  // Форматирование
  private let dateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateStyle = .medium
    df.timeStyle = .none
    return df
  }()

  func formattedDate(_ date: Date) -> String {
    dateFormatter.string(from: date)
  }

  func formattedPrice(_ price: Double) -> String {
    let nf = NumberFormatter()
    nf.numberStyle = .currency
    nf.currencyCode = "RSD"
    nf.maximumFractionDigits = 0
    return nf.string(from: NSNumber(value: price)) ?? "\(Int(price)) RSD"
  }

  func title(for type: ServiceInfo.ServiceType) -> String {
    switch type {
    case .service: return "Сервис"
    case .refuelling: return "Заправка"
    }
  }

  func petrolTitle(for type: ServiceInfo.PetrolType) -> String {
    switch type {
    case .diesel: return "Дизель"
    case .petrol92: return "АИ-92"
    case .petrol95: return "АИ-95"
    case .petrol98: return "АИ-98"
    case .petrol100: return "АИ-100"
    }
  }

  // Удаление записи (по свайпу)
  func removeService(id: String) {
    serviceSession.remove(id: id)
  }
}
