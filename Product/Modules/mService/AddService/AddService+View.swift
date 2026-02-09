import SwiftUI
import Factory

struct AddServiceView: View {
  @Environment(\.dismiss) private var dismiss

  @StateObject private var model: AddServiceModel
  @State private var showIntervalSettings = false

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
          ServiceTemplateSection(model: model, showIntervalSettings: $showIntervalSettings)
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
      .sheet(isPresented: $showIntervalSettings) {
        if let template = model.selectedTemplate {
          ServiceIntervalSettingsSheet(
            template: template,
            customMileageIntervalText: $model.customMileageIntervalText,
            customTimeIntervalText: $model.customTimeIntervalText,
            saveIntervalForFuture: $model.saveIntervalForFuture
          )
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

// MARK: - Под-вью для выбора шаблона
private struct ServiceTemplateSection: View {
  @ObservedObject var model: AddServiceModel
  @Binding var showIntervalSettings: Bool
  
  var body: some View {
    Section {
      Picker("Шаблон сервиса", selection: $model.selectedTemplateId) {
        Text("Без шаблона").tag(nil as String?)
        ForEach(ServiceTemplate.allTemplates, id: \.id) { template in
          Text(template.name.displayName).tag(template.id as String?)
        }
      }
      .pickerStyle(.navigationLink)
      .onChange(of: model.selectedTemplateId) { oldValue, newValue in
        if let templateId = newValue,
           let template = ServiceTemplate.allTemplates.first(where: { $0.id == templateId }) {
          model.selectTemplate(template)
        }
      }
      
      if let template = model.selectedTemplate {
        // Информация об интервале (показываем эффективный - кастомный или дефолтный)
        IntervalInfoView(
          template: template,
          customMileageInterval: model.customMileageInterval,
          customTimeInterval: model.customTimeInterval,
          onSettingsTap: { showIntervalSettings = true }
        )
      }
    } header: {
      Label("Регулярный сервис", systemImage: "repeat")
    } footer: {
      Text("Выберите шаблон для автоматического напоминания о следующей замене.")
        .foregroundColor(.secondary)
    }
  }
  
  private func intervalTimeText(_ days: Int) -> String {
    let years = days / 365
    let months = (days % 365) / 30
    if years > 0 {
      return years == 1 ? "Каждые 1 год" : "Каждые \(years) года"
    } else if months > 0 {
      return months == 1 ? "Каждые 1 месяц" : "Каждые \(months) месяца"
    } else {
      return days == 1 ? "Каждые 1 день" : "Каждые \(days) дней"
    }
  }
}

// MARK: - Отображение информации об интервале
private struct IntervalInfoView: View {
  let template: ServiceTemplate
  let customMileageInterval: Int?
  let customTimeInterval: Int?
  let onSettingsTap: () -> Void
  
  var effectiveMileageInterval: Int? {
    customMileageInterval ?? template.defaultMileageInterval
  }
  
  var effectiveTimeInterval: Int? {
    customTimeInterval ?? template.defaultTimeInterval
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if effectiveMileageInterval != nil || effectiveTimeInterval != nil {
        VStack(alignment: .leading, spacing: 4) {
          Text("Интервал:")
            .font(.caption)
            .foregroundColor(.secondary)
          if let mileageInterval = effectiveMileageInterval {
            Label("Каждые \(mileageInterval) км", systemImage: "speedometer")
              .font(.subheadline)
          }
          if let timeInterval = effectiveTimeInterval {
            Label(intervalTimeText(timeInterval), systemImage: "calendar")
              .font(.subheadline)
          }
        }
      }
      
      Button(action: onSettingsTap) {
        HStack {
          Image(systemName: "slider.horizontal.3")
          Text("Настроить интервал")
        }
      }
    }
    .padding(.vertical, 4)
  }
  
  private func intervalTimeText(_ days: Int) -> String {
    let years = days / 365
    let months = (days % 365) / 30
    if years > 0 {
      return years == 1 ? "Каждые 1 год" : "Каждые \(years) года"
    } else if months > 0 {
      return months == 1 ? "Каждые 1 месяц" : "Каждые \(months) месяца"
    } else {
      return days == 1 ? "Каждые 1 день" : "Каждые \(days) дней"
    }
  }
}

// MARK: - Bottom Sheet для настройки интервала
private struct ServiceIntervalSettingsSheet: View {
  @Environment(\.dismiss) private var dismiss
  
  let template: ServiceTemplate
  @Binding var customMileageIntervalText: String
  @Binding var customTimeIntervalText: String
  @Binding var saveIntervalForFuture: Bool
  
  var body: some View {
    NavigationStack {
      Form {
        Section {
          // Поле для интервала по пробегу (показываем если есть в шаблоне)
          if template.defaultMileageInterval != nil {
            VStack(alignment: .leading, spacing: 8) {
              Text("Интервал по пробегу")
                .font(.headline)
              
              HStack {
                TextField(
                  "\(template.defaultMileageInterval ?? 0)",
                  text: $customMileageIntervalText
                )
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                Text("км")
                  .foregroundColor(.secondary)
              }
              
              Text("По умолчанию: \(template.defaultMileageInterval ?? 0) км")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
          
          // Поле для интервала по времени (показываем если есть в шаблоне)
          if template.defaultTimeInterval != nil {
            VStack(alignment: .leading, spacing: 8) {
              Text("Интервал по времени")
                .font(.headline)
              
              HStack {
                TextField(
                  "\(template.defaultTimeInterval ?? 0)",
                  text: $customTimeIntervalText
                )
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                Text("дней")
                  .foregroundColor(.secondary)
              }
              
              Text("По умолчанию: \(intervalTimeText(template.defaultTimeInterval ?? 0))")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
        } header: {
          Text("Настройка интервала")
        } footer: {
          Text("Оставьте поля пустыми, чтобы использовать интервал по умолчанию.")
        }
        
        Section {
          Toggle("Сохранить для всех будущих замен", isOn: $saveIntervalForFuture)
        } footer: {
          Text("Если включено, этот интервал будет использоваться для всех будущих сервисов этого типа на этом мотоцикле.")
        }
      }
      .navigationTitle("Настройка интервала")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Готово") {
            dismiss()
          }
        }
      }
    }
  }
  
  private func intervalTimeText(_ days: Int) -> String {
    let years = days / 365
    let months = (days % 365) / 30
    if years > 0 {
      return years == 1 ? "1 год" : "\(years) года"
    } else if months > 0 {
      return months == 1 ? "1 месяц" : "\(months) месяца"
    } else {
      return days == 1 ? "1 день" : "\(days) дней"
    }
  }
}

// MARK: - Под-вью для сервиса
private struct ServiceFormSection: View {
  @ObservedObject var model: AddServiceModel

  var body: some View {
    Section {
      if model.selectedTemplateId != nil {
        Text(model.name.isEmpty ? "—" : model.name)
          .foregroundColor(model.name.isEmpty ? .secondary : .primary)
      } else {
        TextField("Название работ", text: $model.name)
          .textInputAutocapitalization(.sentences)
      }
    } header: {
      Label("Название", systemImage: "wrench.and.screwdriver")
    } footer: {
      if model.selectedTemplateId == nil && model.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
