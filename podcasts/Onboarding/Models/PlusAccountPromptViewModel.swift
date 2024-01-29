import UIKit

class PlusAccountPromptViewModel: PlusPricingInfoModel {
    weak var parentController: UIViewController? = nil

    var source: Source = .unknown

    let subscription: UserInfo.Subscription? = .init()

    lazy var products: [PlusProductPricingInfo] = {
        let productsToDisplay: [IAPProductID] = {
            return subscription?.tier == .patron ? [.patronYearly] : [.yearly, .patronYearly]
        }()

        return productsToDisplay.compactMap { product in
            pricingInfo.products.first(where: { $0.identifier == product })
        }
    }()

    override init(purchaseHandler: IAPHelper = .shared) {
        super.init(purchaseHandler: purchaseHandler)

        // Load prices on init
        loadPrices()
    }

    func upgradeTapped(with product: PlusProductPricingInfo? = nil) {
        loadPrices {
            switch self.priceAvailability {
            case .available:
                self.showModal(for: product)
            case .failed:
                self.showError()
            default:
                break
            }
        }
    }

    /// Returns the label that should be displayed on an upgrade button
    func upgradeLabel(for product: PlusProductPricingInfo) -> String {
        let plan = product.identifier.plan
        let expiringPlus = subscription?.isExpiring(.plus) == true

        switch plan {
        case .patron:
            return {
                // Show the renew your sub title
                if subscription?.isExpiring(.patron) == true {
                    return L10n.renewSubscription
                }

                // If the user has an expiring plus subscription show the 'Upgrade Account' title
                return expiringPlus ? L10n.upgradeAccount : L10n.patronSubscribeTo
            }()

        case .plus:
            // Show 'Renew Sub' title if it's expiring
            return {
                if expiringPlus {
                    return L10n.renewSubscription
                }

                return L10n.plusSubscribeTo
            }()
        }
    }

    enum Source: String {
        case unknown
        case accountDetails = "account_details"
        case plusDetails = "plus_details"
    }

    func showModal(for product: PlusProductPricingInfo? = nil) {
        guard let parentController, let product else { return }

        let controller = PlusPurchaseModel.make(in: parentController, plan: product.identifier.plan, selectedPrice: .yearly)
        if let sheetPresentationController = controller.sheetPresentationController {
            sheetPresentationController.prefersGrabberVisible = true
            let detents: [UISheetPresentationController.Detent] = UIScreen.isSmallScreen ? [.large()] : [.medium()]
            sheetPresentationController.detents = detents
        }
        parentController.presentFromRootController(controller, animated: true)
    }

    func showError() {
        SJUIUtils.showAlert(title: L10n.plusUpgradeNoInternetTitle, message: L10n.plusUpgradeNoInternetMessage, from: parentController)
    }
}
