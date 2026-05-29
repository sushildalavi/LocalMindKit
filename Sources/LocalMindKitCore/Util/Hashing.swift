import CryptoKit
import Foundation

public enum Hashing {
  /// SHA-256 of raw bytes, hex-encoded. Used for dedup and change detection.
  public static func sha256(_ data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
  }
}
