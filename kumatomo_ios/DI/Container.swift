import Foundation
import Factory

// MARK: - DI Container

//
// Container extensions are split by architectural layer:
// - Container+Repositories.swift  → Data Layer (Repositories)
// - Container+Services.swift      → Infrastructure Layer (API Services, Managers)
// - Container+UseCases.swift      → Domain Layer (Use Cases)
//

extension Container {
    // Base container configuration can be added here if needed
}
