import Foundation

actor BiometricsCache {
  private var storage: [String: [BiometricsDaily]] = [:]

  func get(days: Int) -> [BiometricsDaily]? {
    storage["\(days)d"]
  }

  func set(days: Int, values: [BiometricsDaily]) {
    storage["\(days)d"] = values
  }
}
