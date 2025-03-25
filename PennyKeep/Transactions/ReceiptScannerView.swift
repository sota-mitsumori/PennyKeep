import SwiftUI
import VisionKit
import Vision

struct ReceiptScannerView: UIViewControllerRepresentable {
    var completion: (String, String, Date) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var parent: ReceiptScannerView

        init(_ parent: ReceiptScannerView) {
            self.parent = parent
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            controller.dismiss(animated: true) {
                var fullText = ""
                let group = DispatchGroup()
                
                for pageIndex in 0..<scan.pageCount {
                    print("Starting text recognition for page \(pageIndex)")
                    group.enter()
                    let image = scan.imageOfPage(at: pageIndex)
                    guard let cgImage = image.cgImage else {
                        print("No CGImage found for page \(pageIndex)")
                        group.leave()
                        continue
                    }
                    
                    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                    let request = VNRecognizeTextRequest { (request, error) in
                        if let error = error {
                            print("Error in text recognition request for page \(pageIndex): \(error.localizedDescription)")
                        }
                        if let results = request.results as? [VNRecognizedTextObservation] {
                            for observation in results {
                                if let candidate = observation.topCandidates(1).first {
                                    print("Recognized text on page \(pageIndex): \(candidate.string)")
                                    fullText += candidate.string + "\n"
                                }
                            }
                        } else {
                            print("No text recognized on page \(pageIndex)")
                        }
                        group.leave()
                    }
                    request.recognitionLevel = .accurate
                    request.automaticallyDetectsLanguage = true
                    
                    DispatchQueue.global(qos: .userInitiated).async {
                        do {
                            try requestHandler.perform([request])
                        } catch {
                            print("Error performing text recognitionon on page \(pageIndex): \(error.localizedDescription)")
                            group.leave()
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    EnvironmentProcessor.processReceiptText(fullText) {
                        title, amount, date in
                        print("Scanned data: title: \(title), amount: \(amount), date: \(date)")
                        self.parent.completion(title, amount, date)
                    }
                }
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            controller.dismiss(animated: true)
        }
    }
}
