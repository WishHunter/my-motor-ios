import Foundation

// MARK: - JSON Loading Extension
extension Bundle {
  /// Загружает и декодирует JSON файл из Bundle
  /// - Parameters:
  ///   - resource: Имя ресурса без расширения
  ///   - type: Тип для декодирования
  /// - Returns: Декодированный объект или nil при ошибке
  func loadJSON<T: Decodable>(resource: String, as type: T.Type) -> T? {
    do {
      guard let url = url(forResource: resource, withExtension: "json") else {
        throw LocalJSONError.fileNotFound
      }
      
      let data = try Data(contentsOf: url)
      return try JSONDecoder().decode(type, from: data)
    } catch {
      print("Error loading JSON '\(resource)': \(error)")
      return nil
    }
  }
}

// MARK: - Async JSON Loading
extension Bundle {
  /// Асинхронно загружает и декодирует JSON файл из Bundle
  /// - Parameters:
  ///   - resource: Имя ресурса без расширения
  ///   - type: Тип для декодирования
  /// - Returns: Декодированный объект или nil при ошибке
  func loadJSONAsync<T: Decodable>(resource: String, as type: T.Type) async -> T? {
    return await withCheckedContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async {
        let result = self.loadJSON(resource: resource, as: type)
        continuation.resume(returning: result)
      }
    }
  }
}

// MARK: - Convenience Methods for Common Types
extension Bundle {
  /// Универсальный метод для загрузки JSON с автоматическим определением типа
  /// - Parameter resource: Имя ресурса без расширения
  /// - Returns: Декодированный объект или nil при ошибке
  func load<T: Decodable>(_ resource: String, as type: T.Type) async -> T? {
    return await loadJSONAsync(resource: resource, as: type)
  }
  
  /// Универсальный метод для загрузки JSON с автоматическим определением типа (с дефолтным значением)
  /// - Parameters:
  ///   - resource: Имя ресурса без расширения
  ///   - type: Тип для декодирования
  ///   - defaultValue: Значение по умолчанию при ошибке
  /// - Returns: Декодированный объект или значение по умолчанию
  func load<T: Decodable>(_ resource: String, as type: T.Type, default defaultValue: T) async -> T {
    return await loadJSONAsync(resource: resource, as: type) ?? defaultValue
  }
}
