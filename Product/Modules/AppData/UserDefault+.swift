import Foundation
import Combine
import os.log

// MARK: - UserDefaults Property Wrapper
/// Property wrapper для удобной работы с UserDefaults
@propertyWrapper
public struct UserDefault<Value: Codable> {
  private let key: String
  private let defaultValue: Value
  private let container: UserDefaults
  private let publisher = PassthroughSubject<Value, Never>()

  public init(key: String, defaultValue: Value, container: UserDefaults = .standard) {
    self.key = key
    self.defaultValue = defaultValue
    self.container = container
  }

  public var wrappedValue: Value {
    get {
      container.codable(forKey: key) ?? defaultValue
    }
    set {
      let logger = Logger(subsystem: "com.mymotor.app", category: "UserDefaults")
      if let optional = newValue as? AnyOptional, optional.isNil {
        container.removeObject(forKey: key)
      } else {
        container.set(codable: newValue, forKey: key)
      }
      publisher.send(newValue)
    }
  }

  public var projectedValue: AnyPublisher<Value, Never> {
    publisher.eraseToAnyPublisher()
  }
}

// MARK: - Optional Protocol
private protocol AnyOptional {
  var isNil: Bool { get }
}

extension Optional: AnyOptional {
  var isNil: Bool { self == nil }
}

// MARK: - UserDefaults Codable Extensions
public extension UserDefaults {
  /// Сохраняет Codable объект в UserDefaults
  /// - Parameters:
  ///   - codable: Объект для сохранения
  ///   - key: Ключ для сохранения
  func set<C: Encodable>(codable: C, forKey key: String) {
    let logger = Logger(subsystem: "com.mymotor.app", category: "UserDefaults")
    do {
      let encodedData = try JSONEncoder().encode(codable)
      set(encodedData, forKey: key)
      logger.debug("Successfully encoded and saved data for key '\(key)'")
    } catch {
      logger.error("Failed to encode data for key '\(key)': \(error.localizedDescription)")
    }
  }

  /// Загружает Codable объект из UserDefaults
  /// - Parameters:
  ///   - type: Тип объекта для загрузки
  ///   - key: Ключ для загрузки
  /// - Returns: Декодированный объект или nil
  func codable<T: Decodable>(_ type: T.Type = T.self, forKey key: String) -> T? {
    let logger = Logger(subsystem: "com.mymotor.app", category: "UserDefaults")
    guard let savedData = object(forKey: key) as? Data else {
      logger.debug("No data found for key '\(key)'")
      return nil
    }
    
    do {
      let decodedObject = try JSONDecoder().decode(type, from: savedData)
      logger.debug("Successfully decoded data for key '\(key)'")
      return decodedObject
    } catch {
      logger.error("Failed to decode data for key '\(key)': \(error.localizedDescription)")
      return nil
    }
  }
}


