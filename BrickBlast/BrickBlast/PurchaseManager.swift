import StoreKit
import SwiftUI

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    static let removeAdsProductID = "com.bluedot.cozybrickblast.removeads"

    @Published private(set) var removeAdsProduct: Product?
    @Published private(set) var hasRemovedAds = false
    @Published private(set) var isWorking = false
    @Published var message: String?

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.refreshEntitlements()
                }
            }
        }

        Task {
            await loadProduct()
            await refreshEntitlements()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    var displayPrice: String {
        removeAdsProduct?.displayPrice ?? "£2.99"
    }

    func purchaseRemoveAds() async {
        guard let product = removeAdsProduct else {
            await loadProduct()
            guard removeAdsProduct != nil else {
                message = "The purchase is temporarily unavailable. Please try again later."
                return
            }
            await purchaseRemoveAds()
            return
        }

        isWorking = true
        defer { isWorking = false }

        do {
            switch try await product.purchase() {
            case .success(.verified(let transaction)):
                await transaction.finish()
                await refreshEntitlements()
                message = "Ads removed. Thank you!"
            case .success(.unverified):
                message = "Apple could not verify this purchase."
            case .pending:
                message = "The purchase is awaiting approval."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            message = "The purchase could not be completed. Please try again."
        }
    }

    func restorePurchases() async {
        isWorking = true
        defer { isWorking = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            message = hasRemovedAds ? "Your ad-free purchase has been restored." : "No previous Remove Ads purchase was found."
        } catch {
            message = "Purchases could not be restored. Please try again."
        }
    }

    private func loadProduct() async {
        do {
            removeAdsProduct = try await Product.products(for: [Self.removeAdsProductID]).first
        } catch {
            removeAdsProduct = nil
        }
    }

    private func refreshEntitlements() async {
        var entitled = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.removeAdsProductID,
               transaction.revocationDate == nil {
                entitled = true
            }
        }
        hasRemovedAds = entitled
    }
}
