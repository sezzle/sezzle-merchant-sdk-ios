import Foundation

/// A postal address for billing or shipping.
public struct SezzleAddress: Sendable {
    public let name: String?
    public let street: String?
    public let street2: String?
    public let city: String?
    public let state: String?
    public let postalCode: String?
    public let countryCode: String?
    public let phone: String?

    public init(
        name: String? = nil, street: String? = nil, street2: String? = nil,
        city: String? = nil, state: String? = nil, postalCode: String? = nil,
        countryCode: String? = nil, phone: String? = nil
    ) {
        self.name = name; self.street = street; self.street2 = street2
        self.city = city; self.state = state; self.postalCode = postalCode
        self.countryCode = countryCode; self.phone = phone
    }
}
