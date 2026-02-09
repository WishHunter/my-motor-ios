import SwiftUI
import Factory

struct ServiceListView: View {
  @StateObject private var model: ServiceListModel
  @State private var isPresentingAdd: Bool = false
  @State private var editingService: ServiceInfo? = nil

  @InjectedObject(\.motorsSession) private var motorsSession: MotorsSession

  init() {
    _model = StateObject(wrappedValue: ServiceListModel())
  }

  var body: some View {
    Group {
      if motorsSession.mainMotor == nil {
        EmptyMotorsView()
      } else if model.services.isEmpty {
        VStack(spacing: 16) {
          ContentUnavailableView(
            "Нет записей",
            systemImage: "wrench.and.screwdriver",
            description: Text("Добавьте первую запись о сервисе или заправке.")
          )
        }
      } else {
        List {
          let services = model.services
          ForEach(services) { service in
            ServiceRow(
              service: service,
              dateText: model.formattedDate(service.date),
              priceText: model.formattedPrice(service.price),
              titleProvider: model.title(for:),
              petrolTitleProvider: model.petrolTitle(for:)
            )
            .contentShape(Rectangle())
            .onTapGesture {
              editingService = service
            }
          }
          .onDelete { indexSet in
            // Берём snapshot текущего списка и вычисляем id для удаления
            let snapshot = services
            let idsToRemove = indexSet.compactMap { idx in
              snapshot.indices.contains(idx) ? snapshot[idx].id : nil
            }
            idsToRemove.forEach { model.removeService(id: $0) }
          }
        }
        .listStyle(.insetGrouped)
      }
    }
    .navigationTitle("История сервисов")
    .navigationBarTitleDisplayMode(.inline)
    .overlay(alignment: .bottomTrailing) {
      Button(action: { isPresentingAdd = true }) {
        Image(systemName: "plus")
          .font(.system(size: 22, weight: .bold))
          .foregroundColor(.white)
          .frame(width: 56, height: 56)
          .background(
            Circle()
              .fill(Color.blue)
          )
          .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
      }
      .padding()
    }
    .sheet(isPresented: $isPresentingAdd) {
      AddServiceView {
        isPresentingAdd = false
      }
    }
    .sheet(item: $editingService) { service in
      AddServiceView(editingService: service) {
        editingService = nil
      }
    }
  }
}

private struct ServiceRow: View {
  let service: ServiceInfo
  let dateText: String
  let priceText: String
  let titleProvider: (ServiceInfo.ServiceType) -> String
  let petrolTitleProvider: (ServiceInfo.PetrolType) -> String

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: iconName(for: service.type))
        .foregroundColor(service.type == .service ? .blue : .green)
        .font(.title3)

      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text(titleProvider(service.type))
            .font(.headline)
          Spacer()
          Text(priceText)
            .font(.subheadline)
            .foregroundColor(.secondary)
        }

        Text(dateText)
          .font(.caption)
          .foregroundColor(.secondary)

        HStack(spacing: 8) {
          Text("\(service.mileage) км")
            .font(.subheadline)

          if let name = service.name, !name.isEmpty {
            Divider().frame(height: 14)
            Text(name)
              .font(.subheadline)
              .foregroundColor(.primary)
          }

          if let petrol = service.typePetrol {
            Divider().frame(height: 14)
            Text(petrolTitleProvider(petrol))
              .font(.subheadline)
              .foregroundColor(.primary)
          }

          if let volume = service.fuelVolume {
            Divider().frame(height: 14)
            Text("\(volume.description) л.")
              .font(.subheadline)
              .foregroundColor(.primary)
          }
        }
      }
    }
    .padding(.vertical, 6)
  }

  private func iconName(for type: ServiceInfo.ServiceType) -> String {
    switch type {
    case .service: return "wrench.and.screwdriver"
    case .refuelling: return "fuelpump.fill"
    }
  }
}

#Preview {
  NavigationStack {
    ServiceListView()
  }
}
