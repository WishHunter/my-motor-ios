import Foundation
import Combine
import os.log

// MARK: - Persistent Published Property Wrapper
/// Расширение Published для автоматического сохранения в UserDefaults
extension Published where Value: Codable {
  /// Создает Published свойство с автоматическим сохранением в UserDefaults
  /// - Parameters:
  ///   - wrappedValue: Значение по умолчанию
  ///   - key: Ключ для сохранения в UserDefaults
  ///   - container: Контейнер UserDefaults (по умолчанию .standard)
  init(wrappedValue defaultValue: Value, key: String, container: UserDefaults = .standard) {
    // Пытаемся загрузить сохраненное значение
    if let savedData = container.data(forKey: key) {
      do {
        let decodedValue = try JSONDecoder().decode(Value.self, from: savedData)
        self.init(initialValue: decodedValue)
      } catch {
        Logger.persistentStorage.warning("Failed to decode saved data for key '\(key)': \(error.localizedDescription)")
        self.init(initialValue: defaultValue)
      }
    } else {
      self.init(initialValue: defaultValue)
    }

    // Настраиваем автоматическое сохранение при изменениях
    projectedValue
      .sink { newValue in
        do {
          let encodedData = try JSONEncoder().encode(newValue)
          container.set(encodedData, forKey: key)
          Logger.persistentStorage.debug("Successfully saved data for key '\(key)'")
        } catch {
          Logger.persistentStorage.error("Failed to encode data for key '\(key)': \(error.localizedDescription)")
        }
      }
      .store(in: &PersistentStorageManager.shared.cancellables)
  }
}

// MARK: - Logger Extension
private extension Logger {
  static let persistentStorage = Logger(subsystem: "com.mymotor.app", category: "PersistentStorage")
}

// MARK: - Storage Management
private class PersistentStorageManager {
  static let shared = PersistentStorageManager()
  var cancellables = Set<AnyCancellable>()
  
  private init() {}
}
