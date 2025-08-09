import Foundation
import Combine

// MARK: - Publisher Extensions

extension Publisher {
    static func merge<A, B, C>(_ a: A, _ b: B, _ c: C) -> AnyPublisher<A.Output, A.Failure>
    where A: Publisher, B: Publisher, C: Publisher,
          A.Output == B.Output, B.Output == C.Output,
          A.Failure == B.Failure, B.Failure == C.Failure {
        Publishers.Merge3(a, b, c).eraseToAnyPublisher()
    }
}
