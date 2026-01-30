import UIKit
import CoreML

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // UI Elements
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .systemGray6
        iv.layer.cornerRadius = 12
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let resultLabel: UILabel = {
        let label = UILabel()
        label.text = "Select a photo to classify"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let selectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Select Photo", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        setupUI()
        
        selectButton.addTarget(self, action: #selector(selectPhotoTapped), for: .touchUpInside)
    }
    
    private func setupUI() {
        view.addSubview(selectButton)
        view.addSubview(imageView)
        view.addSubview(resultLabel)
        
        NSLayoutConstraint.activate([
            // Select Button
            selectButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            selectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            selectButton.widthAnchor.constraint(equalToConstant: 200),
            selectButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Image View
            imageView.topAnchor.constraint(equalTo: selectButton.bottomAnchor, constant: 30),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            
            // Result Label
            resultLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 30),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    @objc private func selectPhotoTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage else {
            resultLabel.text = "Error loading image"
            return
        }
        
        imageView.image = image
        classifyImage(image)
    }
    
    func classifyImage(_ image: UIImage) {
        resultLabel.text = "Classifying..."
        
        // Ridimensiona a 224x224
        guard let resizedImage = image.resize(to: CGSize(width: 224, height: 224)),
              let pixelBuffer = resizedImage.toPixelBuffer() else {
            resultLabel.text = "Error processing image"
            return
        }
        
        do {
            let config = MLModelConfiguration()
            let model = try ArtClassifier_improved(configuration: config)
            
            // Crea input
            let input = ArtClassifier_improvedInput(image: pixelBuffer)
            
            // Predizione
            let output = try model.prediction(input: input)
            
            // Estrai le probabilità dal MultiArray
            let probabilities = output.var_328
            let labels = ["Monet", "Picasso", "Van Gogh"]
            
            print("DEBUG - PROBABILITIES:")
            var probs: [Double] = []
            for i in 0..<3 {
                let prob = probabilities[i].doubleValue
                probs.append(prob)
                print("  \(labels[i]): \(prob * 100)%")
            }
            
            // Trova il massimo
            guard let maxIndex = probs.enumerated().max(by: { $0.element < $1.element })?.offset else {
                resultLabel.text = "Could not classify"
                return
            }
            
            let predictedClass = labels[maxIndex]
            let confidence = Int(probs[maxIndex] * 100)
            
            DispatchQueue.main.async {
                // Soglia per "Altro autore"
                if confidence < 55 {
                    self.resultLabel.text = "Altro autore\nNon riconosciuto\n\nPotrebbe essere:\n"
                    for i in 0..<3 {
                        let conf = Int(probs[i] * 100)
                        self.resultLabel.text! += "\(labels[i]): \(conf)%\n"
                    }
                } else {
                    var resultText = "\(predictedClass)\n\(confidence)% confidence\n\n"
                    resultText += "Other predictions:\n"
                    for i in 0..<3 {
                        if i != maxIndex {
                            let conf = Int(probs[i] * 100)
                            resultText += "\(labels[i]): \(conf)%\n"
                        }
                    }
                    self.resultLabel.text = resultText
                }
            }
        } catch {
            resultLabel.text = "Error: \(error.localizedDescription)"
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - Image Processing Extensions
extension UIImage {
    func resize(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func toPixelBuffer() -> CVPixelBuffer? {
        let width = Int(size.width)
        let height = Int(size.height)
        
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        
        guard let buffer = pixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(data: pixelData, width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue),
              let cgImage = self.cgImage else {
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return buffer
    }
}
