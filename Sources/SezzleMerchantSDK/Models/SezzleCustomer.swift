import Foundation

/// Customer information sent with the checkout session.
public struct SezzleCustomer: Sendable {
    public let email: String
    public let firstName: String?
    public let lastName: String?
    public let phone: String?
    public let dob: String?
    public let billingAddress: SezzleAddress?
    public let shippingAddress: SezzleAddress?
    public let tokenize: Bool?
    public let recurring: Bool?
    public let recurringMetadata: [String: String]?

    public init(
        email: String, firstName: String? = nil, lastName: String? = nil,
        phone: String? = nil, dob: String? = nil,
        billingAddress: SezzleAddress? = nil, shippingAddress: SezzleAddress? = nil,
        tokenize: Bool? = nil, recurring: Bool? = nil,
        recurringMetadata: [String: String]? = nil
    ) {
        self.email = email; self.firstName = firstName; self.lastName = lastName
        self.phone = phone; self.dob = dob
        self.billingAddress = billingAddress; self.shippingAddress = shippingAddress
        self.tokenize = tokenize; self.recurring = recurring
        self.recurringMetadata = recurringMetadata
    }
}
