import SwiftUI
import GoogleMobileAds
import UIKit

struct NativeAdViewWrapper: UIViewControllerRepresentable {
    let adUnitID: String
    
    func makeUIViewController(context: Context) -> NativeAdViewController {
        let viewController = NativeAdViewController(adUnitID: adUnitID)
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: NativeAdViewController, context: Context) {
        // Update if needed
    }
}

class NativeAdViewController: UIViewController {
    let adUnitID: String
    var nativeAdView: GoogleMobileAds.NativeAdView?
    var adLoader: AdLoader?
    
    init(adUnitID: String) {
        self.adUnitID = adUnitID
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadAd()
    }
    
    private func loadAd() {
        let nativeAdView = GoogleMobileAds.NativeAdView()
        nativeAdView.backgroundColor = UIColor.systemBackground
        self.nativeAdView = nativeAdView
        
        let adLoader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: self,
            adTypes: [.native],
            options: nil
        )
        adLoader.delegate = self
        self.adLoader = adLoader
        
        let request = Request()
        adLoader.load(request)
    }
}

extension NativeAdViewController: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        guard let nativeAdView = nativeAdView else { return }
        
        // Remove existing subviews
        view.subviews.forEach { $0.removeFromSuperview() }
        
        // Set the native ad
        nativeAdView.nativeAd = nativeAd
        
        // Setup ad views
        setupAdViews(in: nativeAdView, with: nativeAd)
        
        // Add to view hierarchy
        nativeAdView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nativeAdView)
        NSLayoutConstraint.activate([
            nativeAdView.topAnchor.constraint(equalTo: view.topAnchor),
            nativeAdView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            nativeAdView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            nativeAdView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        print("❌ Failed to load native ad: \(error.localizedDescription)")
    }
    
    private func setupAdViews(in nativeAdView: GoogleMobileAds.NativeAdView, with nativeAd: NativeAd) {
        // Create container view
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor.systemGray6
        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = true
        
        nativeAdView.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor, constant: -8),
        ])
        
        // Create vertical stack
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
        ])
        
        // Headline
        if let headline = nativeAd.headline {
            let headlineLabel = UILabel()
            headlineLabel.text = headline
            headlineLabel.font = UIFont.boldSystemFont(ofSize: 16)
            headlineLabel.numberOfLines = 2
            headlineLabel.textColor = UIColor.label
            nativeAdView.headlineView = headlineLabel
            stackView.addArrangedSubview(headlineLabel)
        }
        
        // Body
        if let body = nativeAd.body {
            let bodyLabel = UILabel()
            bodyLabel.text = body
            bodyLabel.font = UIFont.systemFont(ofSize: 14)
            bodyLabel.numberOfLines = 3
            bodyLabel.textColor = UIColor.secondaryLabel
            nativeAdView.bodyView = bodyLabel
            stackView.addArrangedSubview(bodyLabel)
        }
        
        // Media view - use MediaView
        let mediaView = MediaView()
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        mediaView.layer.cornerRadius = 8
        mediaView.backgroundColor = UIColor.systemGray5
        nativeAdView.mediaView = mediaView
        stackView.addArrangedSubview(mediaView)
        NSLayoutConstraint.activate([
            mediaView.heightAnchor.constraint(equalToConstant: 120),
        ])
        
        // Advertiser
        if let advertiser = nativeAd.advertiser {
            let advertiserLabel = UILabel()
            advertiserLabel.text = advertiser
            advertiserLabel.font = UIFont.systemFont(ofSize: 12)
            advertiserLabel.textColor = UIColor.secondaryLabel
            nativeAdView.advertiserView = advertiserLabel
            stackView.addArrangedSubview(advertiserLabel)
        }
        
        // Call to action button
        if let callToAction = nativeAd.callToAction {
            let ctaButton = UIButton(type: .system)
            ctaButton.setTitle(callToAction, for: .normal)
            ctaButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            ctaButton.backgroundColor = UIColor.systemBlue
            ctaButton.setTitleColor(.white, for: .normal)
            ctaButton.layer.cornerRadius = 8
            ctaButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
            nativeAdView.callToActionView = ctaButton
            stackView.addArrangedSubview(ctaButton)
        }
        
        // Native ad is already set via nativeAdView.nativeAd = nativeAd above
        // No need to call register() in the new API
    }
}

// SwiftUI wrapper for easier use
struct NativeAdViewContainer: View {
    // IMPORTANT: Currently using TEST ad unit ID for development
    // Before publishing, replace with production ad unit ID: "ca-app-pub-7988808089932042/3130582796"
    let adUnitID: String
    
    init(adUnitID: String = "ca-app-pub-3940256099942544/3986624511") {
        self.adUnitID = adUnitID
    }
    
    var body: some View {
        NativeAdViewWrapper(adUnitID: adUnitID)
            .frame(height: 300)
            .padding(.vertical, 8)
    }
}
