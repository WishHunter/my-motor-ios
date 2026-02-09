import SwiftUI
import Factory

struct AddServiceView: View {
  @Environment(\.dismiss) private var dismiss

  @StateObject private var model: AddServiceModel

  @InjectedObject(\.motorsSession) var motorsSession: MotorsSession

  typealias OnSuccessAction = () -> Void
  let onSuccess: OnSuccessAction?

  init(editingService: ServiceInfo? = nil, onSuccess: OnSuccessAction? = nil) {
    _model = StateObject(wrappedValue: AddServiceModel(editingService: editingService))
    self.onSuccess = onSuccess
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          Picker("Тип записи", selection: $model.type) {
            ForEach(ServiceInfo.ServiceType.allCases, id: \.self) { t in
              Text(title(for: t)).tag(t)
            }
          }
          .pickerStyle(.segmented)
          .disabled(model.isEditing)
        } header: {
          Label("Тип", systemImage: "square.and.pencil")
        }

        // Специфичные секции
        if model.type == .service {
          ServiceFormSection(model: model)
        } else if model.type == .refuelling {
          RefuellingFormSection(model: model)
        }

        // Общие секции
        DateSection(date: $model.date)

        MileageSection(
          mileageText: $model.mileageText,
          isValid: model.isMileageValid,
          placeholderMileage: motorsSession.mainMotor?.mileage ?? 0
        )

        PriceSection(
          priceText: $model.priceText,
          isValid: model.isPriceValid
        )
      }
      .navigationTitle(model.isEditing ? "Редактировать запись" : "Новая запись")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Отмена") { dismiss() }
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button("Сохранить") {
            model.save()
            onSuccess?()
            dismiss()
          }
          .disabled(model.isSaveDisabled)
        }
      }
    }
  }

  private func title(for type: ServiceInfo.ServiceType) -> String {
    switch type {
    case .service: return "Сервис"
    case .refuelling: return "Заправка"
    }
  }

  private func petrolTitle(for type: ServiceInfo.PetrolType) -> String {
    switch type {
    case .diesel: return "Дизель"
    case .petrol92: return "АИ-92"
    case .petrol95: return "АИ-95"
    case .petrol98: return "АИ-98"
    case .petrol100: return "АИ-100"
    }
  }
}

// MARK: - Под-вью для сервиса
private struct ServiceFormSection: View {
  @ObservedObject var model: AddServiceModel

  var body: some View {
    Section {
      TextField("Название работ", text: $model.name)
        .textInputAutocapitalization(.sentences)
    } header: {
      Label("Название", systemImage: "wrench.and.screwdriver")
    } footer: {
      if model.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        Text("Опишите, что именно делали.").foregroundColor(.secondary)
      }
    }
  }
}

// MARK: - Под-вью для заправки
private struct RefuellingFormSection: View {
  @ObservedObject var model: AddServiceModel

  var body: some View {
    Section {
      Picker("Тип топлива", selection: $model.typePetrol) {
        ForEach(ServiceInfo.PetrolType.allCases, id: \.self) { p in
          Text(petrolTitle(for: p)).tag(p)
        }
      }
      .pickerStyle(.navigationLink)

      HStack {
        TextField("Объем", text: $model.fuelVolumeText)
          .keyboardType(.decimalPad)
        Text("л").foregroundColor(.secondary)
      }
      if !model.fuelVolumeText.isEmpty && !model.isFuelVolumeValid {
        Text("Введите корректный объем (0–200 л)")
          .font(.caption)
          .foregroundColor(.red)
      }
    } header: {
      Label("Топливо", systemImage: "fuelpump.fill")
    } footer: {
      Text("Укажите тип и количество заправленного топлива.")
    }
  }

  private func petrolTitle(for type: ServiceInfo.PetrolType) -> String {
    switch type {
    case .diesel: return "Дизель"
    case .petrol92: return "АИ-92"
    case .petrol95: return "АИ-95"
    case .petrol98: return "АИ-98"
    case .petrol100: return "АИ-100"
    }
  }
}

// MARK: - Общие секции формы
private struct DateSection: View {
  @Binding var date: Date

  var body: some View {
    Section {
      DatePicker("Дата", selection: $date, displayedComponents: .date)
    } header: {
      Label("Дата", systemImage: "calendar")
    }
  }
}

private struct MileageSection: View {
  @Binding var mileageText: String
  let isValid: Bool
  let placeholderMileage: Int

  var body: some View {
    Section {
      HStack {
        TextField("\(placeholderMileage)", text: $mileageText)
          .keyboardType(.numberPad)
        Text("км").foregroundColor(.secondary)
      }
      if !mileageText.isEmpty && !isValid {
        Text("Введите корректный пробег (0–2 000 000 км)")
          .font(.caption)
          .foregroundColor(.red)
      }
    } header: {
      Label("Пробег", systemImage: "speedometer")
    } footer: {
      Text("Укажите пробег на момент записи.")
    }
  }
}

private struct PriceSection: View {
  @Binding var priceText: String
  let isValid: Bool

  var body: some View {
    Section {
      HStack {
        TextField("Стоимость", text: $priceText)
          .keyboardType(.decimalPad)
        Text("RSD").foregroundColor(.secondary)
      }
      if !priceText.isEmpty && !isValid {
        Text("Введите корректную сумму")
          .font(.caption)
          .foregroundColor(.red)
      }
    } header: {
      Label("Стоимость", systemImage: "creditcard")
    } footer: {
      Text("Укажите фактические затраты на сервис или заправку.")
    }
  }
}

#Preview {
  AddServiceView()
}
