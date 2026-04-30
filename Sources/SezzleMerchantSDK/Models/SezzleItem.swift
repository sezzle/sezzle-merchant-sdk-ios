import Foundation

/// A line item in the order.
public struct SezzleItem: Sendable {
    public let name: String
    public let sku: String?
    public let quantity: Int
    public let price: SezzleAmount
    public let brand: String?
    public let imageUrl: String?
    public let productUrl: String?
    public let globalTradeItemNumber: String?
    public let manufacturerPartNumber: String?
    public let categoryPath: String?

    public init(
        name: String, sku: String? = nil, quantity: Int, price: SezzleAmount,
        brand: String? = nil, imageUrl: String? = nil, productUrl: String? = nil,
        globalTradeItemNumber: String? = nil, manufacturerPartNumber: String? = nil,
        categoryPath: String? = nil
    ) {
        self.name = name; self.sku = sku; self.quantity = quantity; self.price = price
        self.brand = brand; self.imageUrl = imageUrl; self.productUrl = productUrl
        self.globalTradeItemNumber = globalTradeItemNumber
        self.manufacturerPartNumber = manufacturerPartNumber
        self.categoryPath = categoryPath
    }
}
