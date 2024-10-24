import SwiftUI
import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils
#if canImport(PulseUI)
import PulseUI
#endif

struct DeveloperMenu: View {
    @State var showingImporter = false
    @State var showingExporter = false
    @State var showing = false

    var body: some View {
        List {
            if #available(iOS 17.0, *) {
                Section {
                    Button(action: {
                        showingImporter.toggle()
                    }, label: {
                        Text("Import Bundle")
                    })
                    .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.pcasts]) { result in
                        switch result {
                        case .success(let url):
                            print("Selected: \(url)")
                            Task {
                                let fileWrapper = try FileWrapper(url: url)
                                try PCBundleDoc.performImport(from: fileWrapper)
                            }
                        case .failure(let error):
                            print("Failed to import pcasts: \(error)")
                        }
                    }
                    Button(action: {
                        showingExporter.toggle()
                    }, label: {
                        Text("Export Bundle")
                    })
                    .fileExporter(isPresented: $showingExporter, document: PCBundleDoc()) { result in
                        switch result {
                        case .success(let url):
                            print("Saved to: \(url)")
                        case .failure(let error):
                            print("Failed to export pcasts: \(error)")
                        }
                    }
                    Button(action: {
                        PCBundleDoc.delete()
                    }, label: {
                        Text("Reset Database + Settings")
                    })
                }
            }
            Section {
                Button(action: {
                    UIPasteboard.general.string = ServerSettings.pushToken()
                }, label: {
                    Text("Copy Push Token")
                })

                Button(action: {
                    UIPasteboard.general.string = ServerConfig.shared.syncDelegate?.uniqueAppId()
                }, label: {
                    Text("Copy Device ID")
                })
            }

            if FeatureFlag.networkDebugging.enabled {
            #if canImport(PulseUI)
                Section {
                    NavigationLink(destination: ConsoleView()) {
                        Text("Network Debugger")
                    }
                }
            #endif
            }

            Section {
                Button("Corrupt Sync Login Token") {
                    ServerSettings.syncingV2Token = "badToken"
                }

                Button("Force Reload Discover") {
                    DiscoverServerHandler.shared.discoveryCache.removeAllCachedResponses()
                    NotificationCenter.postOnMainThread(notification: Constants.Notifications.chartRegionChanged)
                }

                Button("Unsubscribe from all Podcasts") {
                    let podcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)

                    for podcast in podcasts {
                        PodcastManager.shared.unsubscribe(podcast: podcast)
                    }
                }

                Button("Clear all folder information") {
                    DataManager.sharedManager.clearAllFolderInformation()
                }

                Button("Force Reload Feature Flags") {
                    FirebaseManager.refreshRemoteConfig(expirationDuration: 0) { _ in
                        (UIApplication.shared.delegate as? AppDelegate)?.updateRemoteFeatureFlags()
                    }
                }
            }

            Section {
                Button("Set to No Plus") {
                    ServerSettings.setIapUnverifiedPurchaseReceiptDate(nil)
                    SubscriptionHelper.setSubscriptionPaid(Int(0))
                    SubscriptionHelper.setSubscriptionPlatform(Int(0))
                    SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: 30.days).timeIntervalSince1970)
                    SubscriptionHelper.setSubscriptionAutoRenewing(false)
                    SubscriptionHelper.setSubscriptionGiftDays(Int(0))
                    SubscriptionHelper.setSubscriptionFrequency(SubscriptionFrequency.none.rawValue)
                    SubscriptionHelper.setSubscriptionType(SubscriptionType.none.rawValue)
                    SubscriptionHelper.subscriptionTier = .none
                    NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                    HapticsHelper.triggerSubscribedHaptic()
                }

                Button("Set to Paid Plus") {
                    SubscriptionHelper.setSubscriptionPaid(Int(1))
                    SubscriptionHelper.setSubscriptionPlatform(Int(1))
                    SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: 30.days).timeIntervalSince1970)
                    SubscriptionHelper.setSubscriptionAutoRenewing(true)
                    SubscriptionHelper.setSubscriptionGiftDays(Int(0))
                    SubscriptionHelper.setSubscriptionFrequency(SubscriptionFrequency.monthly.rawValue)
                    SubscriptionHelper.setSubscriptionType(SubscriptionType.plus.rawValue)
                    SubscriptionHelper.subscriptionTier = .plus

                    NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                    HapticsHelper.triggerSubscribedHaptic()
                }

                Button("Set to Paid Patron") {
                    SubscriptionHelper.setSubscriptionPaid(Int(1))
                    SubscriptionHelper.setSubscriptionPlatform(Int(1))
                    SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: 30.days).timeIntervalSince1970)
                    SubscriptionHelper.setSubscriptionAutoRenewing(true)
                    SubscriptionHelper.setSubscriptionGiftDays(Int(0))
                    SubscriptionHelper.setSubscriptionFrequency(SubscriptionFrequency.monthly.rawValue)
                    SubscriptionHelper.setSubscriptionType(SubscriptionType.plus.rawValue)
                    SubscriptionHelper.subscriptionTier = .patron

                    NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                    HapticsHelper.triggerSubscribedHaptic()
                }

                Group {
                    Button("Set to 150 Gift Days") {
                        SubscriptionHelper.setSubscriptionPaid(1)
                        SubscriptionHelper.setSubscriptionPlatform(SubscriptionPlatform.gift.rawValue)
                        SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: 150 * 1.days).timeIntervalSince1970)
                        SubscriptionHelper.setSubscriptionAutoRenewing(false)
                        SubscriptionHelper.setSubscriptionGiftDays(150)
                        SubscriptionHelper.setSubscriptionFrequency(SubscriptionFrequency.none.rawValue)
                        SubscriptionHelper.setSubscriptionType(SubscriptionType.plus.rawValue)
                        SubscriptionHelper.subscriptionTier = .plus

                        NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                        HapticsHelper.triggerSubscribedHaptic()
                    }

                    Button("Set to 150 Gift Days and Expiring in 1 day") {
                        SubscriptionHelper.setSubscriptionPaid(1)
                        SubscriptionHelper.setSubscriptionPlatform(SubscriptionPlatform.gift.rawValue)
                        SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: 1.days).timeIntervalSince1970)
                        SubscriptionHelper.setSubscriptionAutoRenewing(false)
                        SubscriptionHelper.setSubscriptionGiftDays(150)
                        SubscriptionHelper.setSubscriptionFrequency(SubscriptionFrequency.none.rawValue)
                        SubscriptionHelper.setSubscriptionType(SubscriptionType.plus.rawValue)
                        SubscriptionHelper.subscriptionTier = .plus

                        NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                        HapticsHelper.triggerSubscribedHaptic()
                    }

                    Button("Set to 150 Gift Days and Expiring in 29 days") {
                        SubscriptionHelper.setSubscriptionPaid(1)
                        SubscriptionHelper.setSubscriptionPlatform(SubscriptionPlatform.gift.rawValue)
                        SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: 30.days).timeIntervalSince1970)
                        SubscriptionHelper.setSubscriptionAutoRenewing(false)
                        SubscriptionHelper.setSubscriptionGiftDays(150)
                        SubscriptionHelper.setSubscriptionFrequency(SubscriptionFrequency.none.rawValue)
                        SubscriptionHelper.setSubscriptionType(SubscriptionType.plus.rawValue)
                        SubscriptionHelper.subscriptionTier = .plus

                        NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                        HapticsHelper.triggerSubscribedHaptic()
                    }

                    Button("Set to Lifetime") {
                        SubscriptionHelper.setSubscriptionPaid(Int(1))
                        SubscriptionHelper.setSubscriptionPlatform(Int(4))
                        SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: 11 * 365.days).timeIntervalSince1970)
                        SubscriptionHelper.setSubscriptionAutoRenewing(false)
                        SubscriptionHelper.setSubscriptionGiftDays(Int(11 * 365.days))
                        SubscriptionHelper.setSubscriptionFrequency(SubscriptionFrequency.none.rawValue)
                        SubscriptionHelper.setSubscriptionType(SubscriptionType.plus.rawValue)
                        SubscriptionHelper.subscriptionTier = .plus

                        NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                        HapticsHelper.triggerSubscribedHaptic()
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Button("Set to Active but Cancelled: Plus") {
                        SubscriptionHelper.setSubscriptionPaid(Int(1))
                        SubscriptionHelper.setSubscriptionPlatform(Int(1))
                        SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: 3.days).timeIntervalSince1970)
                        SubscriptionHelper.setSubscriptionAutoRenewing(false)
                        SubscriptionHelper.setSubscriptionGiftDays(Int(0))
                        SubscriptionHelper.setSubscriptionFrequency(SubscriptionFrequency.none.rawValue)
                        SubscriptionHelper.setSubscriptionType(SubscriptionType.plus.rawValue)
                        SubscriptionHelper.subscriptionTier = .plus

                        NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                        HapticsHelper.triggerSubscribedHaptic()
                    }
                    Text("Expiring in 2 days")
                        .font(Font.footnote)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Button("Set to Active but Cancelled: Patron") {
                        SubscriptionHelper.setSubscriptionPaid(Int(1))
                        SubscriptionHelper.setSubscriptionPlatform(Int(1))
                        SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: 3.days).timeIntervalSince1970)
                        SubscriptionHelper.setSubscriptionAutoRenewing(false)
                        SubscriptionHelper.setSubscriptionGiftDays(Int(0))
                        SubscriptionHelper.setSubscriptionFrequency(SubscriptionFrequency.none.rawValue)
                        SubscriptionHelper.setSubscriptionType(SubscriptionType.plus.rawValue)
                        SubscriptionHelper.subscriptionTier = .patron

                        NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                        HapticsHelper.triggerSubscribedHaptic()
                    }
                    Text("Expiring in 2 days")
                        .font(Font.footnote)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Button("Set to Cancelled and Expired: Plus") {
                        SubscriptionHelper.setSubscriptionPaid(Int(0))
                        SubscriptionHelper.setSubscriptionPlatform(Int(1))
                        SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: (1.days * -1)).timeIntervalSince1970)
                        SubscriptionHelper.setSubscriptionAutoRenewing(false)
                        SubscriptionHelper.setSubscriptionGiftDays(Int(0))
                        SubscriptionHelper.setSubscriptionFrequency(SubscriptionFrequency.none.rawValue)
                        SubscriptionHelper.setSubscriptionType(SubscriptionType.plus.rawValue)
                        SubscriptionHelper.subscriptionTier = .plus

                        NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                        HapticsHelper.triggerSubscribedHaptic()
                    }
                    Text("Cancelled subscription, but has passed expiration date")
                        .font(Font.footnote)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Button("Set to Cancelled and Expired: Patron") {
                        SubscriptionHelper.setSubscriptionPaid(Int(0))
                        SubscriptionHelper.setSubscriptionPlatform(Int(1))
                        SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: (1.days * -1)).timeIntervalSince1970)
                        SubscriptionHelper.setSubscriptionAutoRenewing(false)
                        SubscriptionHelper.setSubscriptionGiftDays(Int(0))
                        SubscriptionHelper.setSubscriptionFrequency(SubscriptionFrequency.none.rawValue)
                        SubscriptionHelper.setSubscriptionType(SubscriptionType.plus.rawValue)
                        SubscriptionHelper.subscriptionTier = .patron

                        NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                        HapticsHelper.triggerSubscribedHaptic()
                    }
                    Text("Cancelled subscription, but has passed expiration date")
                        .font(Font.footnote)
                }

            } header: {
                VStack {
                    Text("Subscription Testing")
                    Text("⚠️ Temporary items only, the changes will only be active until the next server sync.")
                }
            }

            Section {
                EndOfYearDeveloperMenuButton()
            } header: {
                Text("End of Year")
            }

            Section {
                Text(Bundle.main.identifier)
            } header: {
                Text("Bundle ID")
            }
        }
        .modifier(MiniPlayerPadding())
    }
}

struct DeveloperMenu_Previews: PreviewProvider {
    static var previews: some View {
        DeveloperMenu()
    }
}

extension Bundle {

    var identifier: String {
        guard let infoDictionary = infoDictionary, let identifier = infoDictionary["CFBundleIdentifier"] as? String else {
            return "Cound not load bundle id."
        }

        return identifier

    }
}
