import StoreKit
import SwiftUI

@MainActor
class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()
    
    @Published var unlockProduct: Product?
    @Published var gemProducts: [Product] = []
    @Published var isPurchased: Bool = false
    @Published var isLoadingProducts = false
    @Published var isPerformingPurchase = false
    @Published var lastErrorMessage: String?
    
    private let productID = "trace.full.unlock"
    private let gemProductIDs = [
        "trace.gems.50",
        "trace.gems.180",
        "trace.gems.350",
        "trace.gems.800"
    ]
    
    private var updatesTask: Task<Void, Never>? = nil
    private var isInitialized = false
    
    init() {
        self.isPurchased = true
    }
    
    func initialize() {
        guard !isInitialized else { return }
        isInitialized = true
        
        // Start listening to transactions
        updatesTask = Task.detached(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { break }
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.updatePurchasedState()
                }
            }
        }
        
        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            await self.loadProducts()
            await self.updatePurchasedState()
        }
    }
    
    deinit {
        updatesTask?.cancel()
    }
    
    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        
        do {
            let products = try await Product.products(for: [productID])
            self.unlockProduct = products.first
            
            let gems = try await Product.products(for: gemProductIDs)
            self.gemProducts = gems.sorted { $0.price < $1.price }
            print("PurchaseManager: Loaded \(self.gemProducts.count) gem products.")
        } catch {
            print("Failed to load products: \(error)")
            lastErrorMessage = "Unable to load purchase options right now."
        }
    }
    
    func purchase() async {
        if unlockProduct == nil {
            await loadProducts()
        }
        
        guard let product = unlockProduct else {
            lastErrorMessage = "Purchase option unavailable right now."
            return
        }
        
        await purchase(product)
    }
    
    func purchase(_ product: Product) async {
        lastErrorMessage = nil
        isPerformingPurchase = true
        defer { isPerformingPurchase = false }
        
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    
                    // Play purchase success feedback
                    HapticsManager.shared.perfect()
                    SoundManager.shared.perfect()
                    
                    if transaction.productID == productID {
                        self.isPurchased = true
                        ProgressStore.shared.unlockFullGame()
                        await updatePurchasedState()
                    } else if transaction.productID.hasPrefix("trace.gems.") {
                        let gemsToAdd: Int
                        switch transaction.productID {
                        case "trace.gems.50": gemsToAdd = 50
                        case "trace.gems.180": gemsToAdd = 180
                        case "trace.gems.350": gemsToAdd = 350
                        case "trace.gems.800": gemsToAdd = 800
                        default: gemsToAdd = 0
                        }
                        
                        if gemsToAdd > 0 {
                            ProgressStore.shared.addGems(gemsToAdd)
                            print("Gems credited to account: +\(gemsToAdd)")
                        }
                    }
                case .unverified(_, _):
                    lastErrorMessage = "Purchase verification failed."
                }
            case .userCancelled:
                break
            case .pending:
                lastErrorMessage = "Purchase is pending approval."
            @unknown default:
                lastErrorMessage = "Purchase did not complete."
            }
        } catch {
            print("Purchase failed: \(error)")
            lastErrorMessage = "Purchase failed. Please try again."
        }
    }
    
    func restorePurchases() async {
        lastErrorMessage = nil
        isPerformingPurchase = true
        defer { isPerformingPurchase = false }
        
        do {
            try await AppStore.sync()
            await updatePurchasedState()
            if !isPurchased {
                lastErrorMessage = "No prior purchases found to restore."
            }
        } catch {
            print("Restore failed: \(error)")
            lastErrorMessage = "Restore failed. Please try again."
        }
    }
    
    private func updatePurchasedState() async {
        self.isPurchased = true
        ProgressStore.shared.unlockFullGame()
    }
}
