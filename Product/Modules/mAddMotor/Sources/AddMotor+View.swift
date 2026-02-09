import SwiftUI

struct AddMotorView: View {
  @ObservedObject var model = AddMotorModel()

  typealias OnSuccessAction = () -> Void

  let onSuccess: OnSuccessAction?

  init(_ onSuccess: OnSuccessAction? = nil) {
    self.onSuccess = onSuccess
  }

  var body: some View {
    NavigationStack {
      ZStack {
        Form {
          Section {
            Picker("Марка", selection: $model.selectedBrand) {
              Text("— выбери марку, раб —")
                .tag(Optional<BrandResponse>.none)
              ForEach(model.brands, id: \.self) { option in
                Text(option.name).tag(Optional(option))
              }
            }
            .pickerStyle(.navigationLink)
            .disabled(model.isLoading)
          } header: {
            Label("Базовое", systemImage: "car.fill")
          }

          Section {
            Picker("Модель", selection: $model.selectedModel) {
              Text("— выбери модель, раб —")
                .tag(Optional<MotorResponse>.none)
              ForEach(model.models, id: \.self) { option in
                Text(option.name).tag(Optional(option))
              }
            }
            .pickerStyle(.navigationLink)
            .disabled(model.models.isEmpty || model.isLoading)
          } header: {
            Label("Модель", systemImage: "list.bullet")
          } footer: {
            if model.isLoading {
              HStack {
                ProgressView()
                  .scaleEffect(0.8)
                Text("Загрузка моделей...")
                  .font(.caption)
              }
            }
          }

          Section {
            Picker("Год выпуска", selection: $model.selectedYear) {
              Text("— выбери год —")
                .tag(Optional<Int>.none)
              ForEach(model.years, id: \.self) { option in
                Text(String(option)).tag(Optional(option))
              }
            }
            .pickerStyle(.navigationLink)
            .disabled(model.years.isEmpty || model.isLoading)
          } header: {
            Label("Год выпуска", systemImage: "calendar")
          } footer: {
            if model.isLoading {
              HStack {
                ProgressView()
                  .scaleEffect(0.8)
                Text("Загрузка годов...")
                  .font(.caption)
              }
            }
          }

          Section {
            HStack {
              TextField("Пробег", text: $model.mileage)
                .keyboardType(.numberPad)

              if !model.mileage.isEmpty {
                Text("км")
                  .foregroundColor(.secondary)
                  .font(.body)
              } else {
                Text("км")
                  .foregroundColor(.secondary)
                  .font(.body)
              }
            }
          } header: {
            Label("Пробег", systemImage: "speedometer")
          } footer: {
            if !model.mileage.isEmpty && !model.isValidMileage {
              Text("Введите корректный пробег (0-999,999 км)")
                .foregroundColor(.red)
                .font(.caption)
            } else {
              Text("Укажите текущий пробег мотоцикла в километрах")
            }
          }
        }
        .navigationTitle("Добавить мотоцикл")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button("Сохранить") {
              model.saveMotor()

              onSuccess?()
            }
            .disabled(model.isContinueDisabled)
          }
        }
        .onChange(of: model.selectedBrand) { _, newBrand in
          if let brand = newBrand {
            Task { await model.getModels(forBrandWithId: brand.id) }
          } else {
            model.models = []
            model.selectedModel = nil
            model.years = []
            model.selectedYear = nil
          }
        }
        .onChange(of: model.selectedModel) { _, newModel in
          if newModel != nil {
            model.getYears()
          } else {
            model.years = []
            model.selectedYear = nil
          }
        }
        
        // Overlay для полного перекрытия при загрузке брендов
        if model.isLoading && model.brands.isEmpty {
          Color.black.opacity(0.3)
            .ignoresSafeArea()
          
          VStack(spacing: 16) {
            ProgressView()
              .scaleEffect(1.2)
            Text("Загрузка данных...")
              .font(.headline)
          }
          .padding()
          .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
      }
    }
  }
}

#Preview {
  AddMotorView()
}
