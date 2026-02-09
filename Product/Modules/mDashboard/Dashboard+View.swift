import SwiftUI
import Factory

struct DashboardView: View {
  @InjectedObject(\.motorsSession) var motorsSession: MotorsSession
  @Injected(\.serviceReminderManager) var reminderManager: ServiceReminderManager

  @State var openService: Bool = false

  var body: some View {
    ScrollView {
      if let motor = motorsSession.mainMotor {
        VStack(spacing: 20) {
          // Header с основной информацией
          MotorHeaderCard(motor: motor)
          
          // Предстоящие сервисы
          UpcomingServicesCard()
          
          // Характеристики двигателя
          EngineSpecsCard(motor: motor)
          
          // Подвеска и тормоза
          SuspensionBrakesCard(motor: motor)
          
          // Габариты и вес
          DimensionsWeightCard(motor: motor)
          
          // Дополнительная информация
          AdditionalInfoCard(motor: motor)
        }
        .padding()
      } else {
        EmptyMotorsView()
      }
    }
    .navigationTitle("Мой мотоцикл")
    .navigationBarTitleDisplayMode(.inline)
    .overlay(alignment: .bottomTrailing) {
      if !motorsSession.mainMotor.isNil {
        Button(action: { openService = true }) {
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
    }
    .sheet(isPresented: $openService) {
      AddServiceView()
    }
  }
}

// MARK: - Motor Header Card
struct MotorHeaderCard: View {
  let motor: MotorInfo
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("\(motor.make) \(motor.model)")
            .font(.title2)
            .fontWeight(.bold)
          
          Text("\(motor.year) год")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        
        Spacer()
        
        VStack(alignment: .trailing, spacing: 4) {
          Text("\(motor.mileage) км")
            .font(.headline)
            .fontWeight(.semibold)
          
          Text("Пробег")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
      
      Divider()
      
      HStack(spacing: 20) {
        SpecItemView(
          icon: "bolt.fill",
          title: "Двигатель",
          value: motor.info.engineType.rawValue
        )
        
        SpecItemView(
          icon: "arrow.triangle.2.circlepath",
          title: "КПП",
          value: motor.info.transmission.rawValue
        )
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
  }
}

// MARK: - Engine Specs Card
struct EngineSpecsCard: View {
  let motor: MotorInfo
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      CardHeaderView(title: "Двигатель", icon: "bolt.fill")
      
      LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible())
      ], spacing: 16) {
        SpecValueView(
          title: "Объем",
          value: "\(Int(motor.info.displacement)) cc",
          icon: "cylinder.fill"
        )
        
        SpecValueView(
          title: "Мощность",
          value: "\(motor.info.power) л.с.",
          icon: "bolt.fill"
        )
        
        SpecValueView(
          title: "Крутящий момент",
          value: "\(motor.info.torque) Н⋅м",
          icon: "arrow.triangle.2.circlepath"
        )
        
        SpecValueView(
          title: "Охлаждение",
          value: motor.info.coolingSystem.rawValue,
          icon: "thermometer"
        )
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
  }
}

// MARK: - Suspension & Brakes Card
struct SuspensionBrakesCard: View {
  let motor: MotorInfo
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      CardHeaderView(title: "Подвеска и тормоза", icon: "car.fill")
      
      VStack(spacing: 12) {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Передняя подвеска")
              .font(.caption)
              .foregroundColor(.secondary)
            Text(motor.info.frontSuspension.displayName)
              .font(.subheadline)
              .fontWeight(.medium)
          }
          
          Spacer()
          
          VStack(alignment: .trailing, spacing: 4) {
            Text("Ход")
              .font(.caption)
              .foregroundColor(.secondary)
            Text("\(Int(motor.info.frontWheelTravel)) мм")
              .font(.subheadline)
              .fontWeight(.medium)
          }
        }
        
        Divider()
        
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Задняя подвеска")
              .font(.caption)
              .foregroundColor(.secondary)
            Text(motor.info.rearSuspension.displayName)
              .font(.subheadline)
              .fontWeight(.medium)
          }
          
          Spacer()
          
          VStack(alignment: .trailing, spacing: 4) {
            Text("Ход")
              .font(.caption)
              .foregroundColor(.secondary)
            Text("\(Int(motor.info.rearWheelTravel)) мм")
              .font(.subheadline)
              .fontWeight(.medium)
          }
        }
        
        Divider()
        
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Передние тормоза")
              .font(.caption)
              .foregroundColor(.secondary)
            Text(motor.info.frontBrake.rawValue)
              .font(.subheadline)
              .fontWeight(.medium)
          }
          
          Spacer()
          
          VStack(alignment: .leading, spacing: 4) {
            Text("Задние тормоза")
              .font(.caption)
              .foregroundColor(.secondary)
            Text(motor.info.rearBrake.rawValue)
              .font(.subheadline)
              .fontWeight(.medium)
          }
        }
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
  }
}

// MARK: - Dimensions & Weight Card
struct DimensionsWeightCard: View {
  let motor: MotorInfo
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      CardHeaderView(title: "Габариты и вес", icon: "ruler.fill")
      
      LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible())
      ], spacing: 16) {
        SpecValueView(
          title: "Вес",
          value: "\(Int(motor.info.totalWeight)) кг",
          icon: "scalemass.fill"
        )
        
        SpecValueView(
          title: "Высота сиденья",
          value: "\(Int(motor.info.seatHeight)) мм",
          icon: "person.fill"
        )
        
        SpecValueView(
          title: "Колесная база",
          value: "\(Int(motor.info.wheelbase)) мм",
          icon: "arrow.left.and.right"
        )
        
        SpecValueView(
          title: "Дорожный просвет",
          value: "\(Int(motor.info.groundClearance)) мм",
          icon: "arrow.up.and.down"
        )
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
  }
}

// MARK: - Additional Info Card
struct AdditionalInfoCard: View {
  let motor: MotorInfo
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      CardHeaderView(title: "Дополнительно", icon: "info.circle.fill")
      
      VStack(spacing: 12) {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Объем бака")
              .font(.caption)
              .foregroundColor(.secondary)
            Text("\(Int(motor.info.fuelCapacity)) л")
              .font(.subheadline)
              .fontWeight(.medium)
          }
          
          Spacer()
          
          VStack(alignment: .trailing, spacing: 4) {
            Text("Стартер")
              .font(.caption)
              .foregroundColor(.secondary)
            Text(motor.info.starter.rawValue)
              .font(.subheadline)
              .fontWeight(.medium)
          }
        }
        
        Divider()
        
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Передняя шина")
              .font(.caption)
              .foregroundColor(.secondary)
            Text(motor.info.frontTire)
              .font(.subheadline)
              .fontWeight(.medium)
          }
          
          Spacer()
          
          VStack(alignment: .trailing, spacing: 4) {
            Text("Задняя шина")
              .font(.caption)
              .foregroundColor(.secondary)
            Text(motor.info.rearTire)
              .font(.subheadline)
              .fontWeight(.medium)
          }
        }
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
  }
}

// MARK: - Upcoming Services Card
struct UpcomingServicesCard: View {
  @Injected(\.serviceReminderManager) var reminderManager: ServiceReminderManager
  @InjectedObject(\.motorsSession) var motorsSession: MotorsSession
  
  var body: some View {
    let upcomingServices = reminderManager.getServicesRequiringAttention()
    let currentMileage = motorsSession.mainMotor?.mileage ?? 0
    
    if !upcomingServices.isEmpty {
      VStack(alignment: .leading, spacing: 16) {
        CardHeaderView(title: "Предстоящие сервисы", icon: "bell.fill")
        
        VStack(spacing: 12) {
          ForEach(upcomingServices.prefix(5)) { service in
            UpcomingServiceRow(service: service, currentMileage: currentMileage)
            if service.id != upcomingServices.prefix(5).last?.id {
              Divider()
            }
          }
        }
      }
      .padding()
      .background(Color(.systemBackground))
      .cornerRadius(12)
      .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
  }
}

// MARK: - Upcoming Service Row
struct UpcomingServiceRow: View {
  let service: ServiceReminderManager.UpcomingService
  let currentMileage: Int
  
  var body: some View {
    HStack(spacing: 12) {
      // Индикатор статуса
      Circle()
        .fill(statusColor)
        .frame(width: 8, height: 8)
      
      VStack(alignment: .leading, spacing: 4) {
        Text(service.templateName)
          .font(.subheadline)
          .fontWeight(.medium)
        
        HStack(spacing: 8) {
          if let nextMileage = service.nextServiceMileage {
            let remaining = nextMileage - currentMileage
            if remaining > 0 {
              Label("Осталось: \(remaining) км", systemImage: "speedometer")
                .font(.caption)
                .foregroundColor(.secondary)
            } else {
              Label("Просрочено на \(abs(remaining)) км", systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(.red)
            }
          }
          
          if let nextDate = service.nextServiceDate {
            let calendar = Calendar.current
            let now = Date()
            if nextDate <= now {
              Label("Просрочено", systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(.red)
            } else {
              let daysUntil = calendar.dateComponents([.day], from: now, to: nextDate).day ?? 0
              if daysUntil <= 7 {
                Label("Через \(daysUntil) дн.", systemImage: "calendar")
                  .font(.caption)
                  .foregroundColor(.orange)
              } else {
                Label("Через \(daysUntil) дн.", systemImage: "calendar")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            }
          }
        }
      }
      
      Spacer()
      
      // Иконка статуса
      Image(systemName: statusIcon)
        .foregroundColor(statusColor)
        .font(.headline)
    }
  }
  
  private var statusColor: Color {
    switch service.status {
    case .onTime: return .green
    case .soon: return .orange
    case .overdue: return .red
    }
  }
  
  private var statusIcon: String {
    switch service.status {
    case .onTime: return "checkmark.circle.fill"
    case .soon: return "exclamationmark.circle.fill"
    case .overdue: return "xmark.circle.fill"
    }
  }
}

// MARK: - Helper Views
struct CardHeaderView: View {
  let title: String
  let icon: String
  
  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: icon)
        .foregroundColor(.blue)
        .font(.headline)
      
      Text(title)
        .font(.headline)
        .fontWeight(.semibold)
      
      Spacer()
    }
  }
}

struct SpecItemView: View {
  let icon: String
  let title: String
  let value: String
  
  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: icon)
        .foregroundColor(.blue)
        .font(.subheadline)
      
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.caption)
          .foregroundColor(.secondary)
        Text(value)
          .font(.subheadline)
          .fontWeight(.medium)
      }
      
      Spacer()
    }
  }
}

struct SpecValueView: View {
  let title: String
  let value: String
  let icon: String
  
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: icon)
        .foregroundColor(.blue)
        .font(.title2)
      
      VStack(spacing: 2) {
        Text(title)
          .font(.caption)
          .foregroundColor(.secondary)
        Text(value)
          .font(.subheadline)
          .fontWeight(.semibold)
          .multilineTextAlignment(.center)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 8)
  }
}

#Preview {
  DashboardView()
    .inNavigationStack()
}
