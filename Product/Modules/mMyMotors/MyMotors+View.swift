import SwiftUI
import Factory

struct MyMotorsView: View {
  @InjectedObject(\.motorsSession) var motorsSession: MotorsSession
  @ObservedObject private var model = MyMotorsModel()

  var body: some View {
    ScrollView {
      if motorsSession.motors.isEmpty {
        EmptyMotorsView()
      } else {
        LazyVStack(spacing: 12) {
          ForEach(motorsSession.motors) { motor in
            MotorCardView(
              motor: motor,
              isMainMotor: model.isMainMotor(motor),
              isSelected: model.selectedMotorId == motor.id,
              onTap: {
                model.handleMotorTap(motor)
              }
            )
          }

          AddMotorButtonView {
            model.showAddMotorSheet()
          }
        }
        .padding()
      }
    }
    .navigationTitle("Мои мотоциклы")
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $model.isAddMotorSheetPresented) {
      AddMotorView {
        model.hideAddMotorSheet()
      }
    }
  }
}

struct AddMotorButtonView: View {
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack {
        Spacer()
        VStack(spacing: 8) {
          Image(systemName: "plus")
          Text("Добавить мотоцикл")
        }
        Spacer()
      }
      .padding()
      .foregroundColor(.primary)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color(.systemBackground))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color(.systemGray4), lineWidth: 1)
      )
      .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
  }
}

struct MotorCardView: View {
  let motor: MotorInfo
  let isMainMotor: Bool
  let isSelected: Bool
  let onTap: () -> Void
  
  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 16) {
        VStack {
          Image(systemName: "motorcycle")
            .font(.system(size: 24))
            .foregroundColor(isMainMotor ? .white : .blue)
          
          if isMainMotor {
            Text("Главный")
              .font(.caption2)
              .fontWeight(.semibold)
              .foregroundColor(.white)
          }
        }
        .frame(width: 50)
        
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text("\(motor.make) \(motor.model)")
              .font(.headline)
              .fontWeight(.semibold)
              .foregroundColor(isMainMotor ? .white : .primary)
            
            Spacer()
            
            if isMainMotor {
              Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .font(.caption)
            }
          }
          
          Text("\(motor.year) год")
            .font(.subheadline)
            .foregroundColor(isMainMotor ? .white.opacity(0.8) : .secondary)
          
          HStack {
            Text("\(motor.mileage) км")
              .font(.subheadline)
              .fontWeight(.medium)
              .foregroundColor(isMainMotor ? .white : .primary)
            
            Spacer()
            
            Text("\(Int(motor.info.displacement))cc • \(motor.info.power) л.с.")
              .font(.caption)
              .foregroundColor(isMainMotor ? .white.opacity(0.8) : .secondary)
          }
        }
        
        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundColor(isMainMotor ? .white.opacity(0.6) : .secondary)
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(
            isMainMotor ? 
              AnyShapeStyle(
                LinearGradient(
                  colors: [.blue, .blue.opacity(0.8)],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              ) : 
              AnyShapeStyle(Color(.systemBackground))
          )
      )
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(
            isMainMotor ? Color.clear : Color(.systemGray4),
            lineWidth: 1
          )
      )
      .shadow(
        color: isMainMotor ? .blue.opacity(0.3) : .black.opacity(0.1),
        radius: isMainMotor ? 8 : 2,
        x: 0,
        y: isMainMotor ? 4 : 1
      )
      .scaleEffect(isSelected ? 1.02 : 1.0)
      .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    .buttonStyle(PlainButtonStyle())
  }
}

extension MotorInfo {
  // Краткое описание мотоцикла для карточки.
  var shortDescription: String {
    return "\(Int(info.displacement))cc • \(info.power) л.с. • \(info.engineType.rawValue)"
  }
}

#Preview {
  MyMotorsView()
    .inNavigationStack()
}
