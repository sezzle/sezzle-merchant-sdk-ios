import Foundation

/// Customer information sent with the checkout session.
///
/// Only `email` is required. Providing additional fields may improve the checkout experience.
///
/// ```swift
/// let customer = SezzleCustomer(
///     email: "jane@example.com",
///     firstName: "Jane",
///     lastName: "Doe"
/// )
/// ```
public struct SezzleCustomer: Sendable {
    /// The customer's email address. Required.
    public let email: String
    /// The customer's first name.
    public let firstName: String?
    /// The customer's last name.
    public let lastName: String?
    /// The customer's phone number.
    public let phone: String?

    public init(email: String, firstName: String? = nil, lastName: String? = nil, phone: String? = nil) {
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
    }
}
