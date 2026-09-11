import Foundation
import SwiftUI

#if canImport(GoogleMobileAds) && canImport(UserMessagingPlatform)
import GoogleMobileAds
import UserMessagingPlatform
#endif

@MainActor
final class AdManager: NSObject, ObservableObject {
    static let shared = AdManager()

    @Published private(set) var isPrivacyOptionsRequired = false

    private var completedRounds = 0
    private var hasStarted = false

#if canImport(GoogleMobileAds) && canImport(UserMessagingPlatform)
    private var interstitial: InterstitialAd?
#endif

    private override init() {
        super.init()
    }

    func configure() {
        guard !hasStarted, !PurchaseManager.shared.hasRemovedAds else { return }
        guard let appID = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String,
              !appID.isEmpty else { return }
        hasStarted = true

#if canImport(GoogleMobileAds) && canImport(UserMessagingPlatform)
        Task { await gatherConsentAndLoadAds() }
#endif
    }

    func recordCompletedRound() {
        guard !PurchaseManager.shared.hasRemovedAds else { return }
        completedRounds += 1
        guard completedRounds.isMultiple(of: 3) else { return }

#if canImport(GoogleMobileAds) && canImport(UserMessagingPlatform)
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            presentInterstitialIfReady()
        }
#endif
    }

    func presentPrivacyOptions() async {
#if canImport(GoogleMobileAds) && canImport(UserMessagingPlatform)
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: nil)
            updatePrivacyOptionsRequirement()
        } catch {
            // A later attempt remains available from Parent Settings.
        }
#endif
    }
}

#if canImport(GoogleMobileAds) && canImport(UserMessagingPlatform)
private extension AdManager {
    var interstitialAdUnitID: String? {
#if DEBUG
        return "ca-app-pub-3940256099942544/4411468910"
#else
        return Bundle.main.object(forInfoDictionaryKey: "GADInterstitialAdUnitID") as? String
#endif
    }

    func gatherConsentAndLoadAds() async {
        let parameters = RequestParameters()
#if DEBUG
        let debugSettings = DebugSettings()
        debugSettings.geography = .other
        parameters.debugSettings = debugSettings
#endif

        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
            try await ConsentForm.loadAndPresentIfRequired(from: nil)
        } catch {
            // Previous consent can still allow ads when the network is unavailable.
        }

        updatePrivacyOptionsRequirement()
        guard ConsentInformation.shared.canRequestAds else { return }

        await MobileAds.shared.start()
        await loadInterstitial()
    }

    func updatePrivacyOptionsRequirement() {
        isPrivacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    func loadInterstitial() async {
        guard !PurchaseManager.shared.hasRemovedAds,
              interstitial == nil,
              let adUnitID = interstitialAdUnitID else { return }

        do {
            interstitial = try await InterstitialAd.load(with: adUnitID, request: Request())
            interstitial?.fullScreenContentDelegate = self
        } catch {
            interstitial = nil
        }
    }

    func presentInterstitialIfReady() {
        guard !PurchaseManager.shared.hasRemovedAds, let interstitial else { return }
        do {
            try interstitial.canPresent(from: nil)
            interstitial.present(from: nil)
        } catch {
            self.interstitial = nil
            Task { await loadInterstitial() }
        }
    }
}

extension AdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        interstitial = nil
        Task { await loadInterstitial() }
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        interstitial = nil
        Task { await loadInterstitial() }
    }
}
#endif
