import UIKit
import CoreML

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Properties
    private var currentImage: UIImage?
    private var currentArtist: String?
    
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
    
    private let artistInfoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("🎨Learn more about the artist", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.alpha = 1.0
        return button
    }()
    
    private let paintingInfoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("🖼️ About this artwork", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .systemOrange
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.alpha = 1.0
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        setupUI()
        
        selectButton.addTarget(self, action: #selector(selectPhotoTapped), for: .touchUpInside)
        artistInfoButton.addTarget(self, action: #selector(artistInfoTapped), for: .touchUpInside)
        paintingInfoButton.addTarget(self, action: #selector(paintingInfoTapped), for: .touchUpInside)
        
        print("✅ ViewController loaded - bottoni configurati")
    }
    
    private func setupUI() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        contentView.addSubview(selectButton)
        contentView.addSubview(imageView)
        contentView.addSubview(resultLabel)
        contentView.addSubview(artistInfoButton)
        contentView.addSubview(paintingInfoButton)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            selectButton.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 20),
            selectButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            selectButton.widthAnchor.constraint(equalToConstant: 200),
            selectButton.heightAnchor.constraint(equalToConstant: 50),
            
            imageView.topAnchor.constraint(equalTo: selectButton.bottomAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.75),
            
            resultLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            resultLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            resultLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            artistInfoButton.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 20),
            artistInfoButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            artistInfoButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            artistInfoButton.heightAnchor.constraint(equalToConstant: 50),
            
            paintingInfoButton.topAnchor.constraint(equalTo: artistInfoButton.bottomAnchor, constant: 10),
            paintingInfoButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            paintingInfoButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            paintingInfoButton.heightAnchor.constraint(equalToConstant: 50),
            
            paintingInfoButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
        
        print("✅ UI Setup completato CON SCROLLVIEW")
    }
    
    @objc private func selectPhotoTapped() {
        print("📸 selectPhotoTapped chiamato")
        
        let alert = UIAlertController(title: "Seleziona Sorgente", message: "Scegli da dove caricare l'immagine", preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            print("✅ Camera disponibile")
            alert.addAction(UIAlertAction(title: "📷 Camera", style: .default) { _ in
                print("📷 Camera selezionata")
                let picker = UIImagePickerController()
                picker.delegate = self
                picker.sourceType = .camera
                picker.allowsEditing = false
                self.present(picker, animated: true)
            })
        } else {
            print("⚠️ Camera NON disponibile")
        }
        
        alert.addAction(UIAlertAction(title: "🖼️ Photo Library", style: .default) { _ in
            print("🖼️ Libreria Foto selezionata")
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary
            picker.allowsEditing = false
            self.present(picker, animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = self.selectButton
            popover.sourceRect = self.selectButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    @objc private func artistInfoTapped() {
        print("🎨 artistInfoTapped chiamato")
        print("   currentArtist: \(String(describing: currentArtist))")
        print("   currentImage: \(currentImage != nil ? "presente" : "nil")")
        
        guard let artist = currentArtist, let image = currentImage else {
            print("❌ Mancano artist o image")
            return
        }
        
        print("✅ Creando ArtistInfoViewController...")
        let infoVC = ArtistInfoViewController()
        infoVC.artistName = artist
        infoVC.artistImage = image
        infoVC.showPaintingInfo = false
        infoVC.modalPresentationStyle = .fullScreen
        
        present(infoVC, animated: true)
        print("✅ ArtistInfoViewController presentato")
    }
    
    @objc private func paintingInfoTapped() {
        print("🖼️ paintingInfoTapped chiamato")
        print("   currentArtist: \(String(describing: currentArtist))")
        print("   currentImage: \(currentImage != nil ? "presente" : "nil")")
        
        guard let artist = currentArtist, let image = currentImage else {
            print("❌ Mancano artist o image")
            return
        }
        
        print("✅ Creando ArtistInfoViewController per painting...")
        let infoVC = ArtistInfoViewController()
        infoVC.artistName = artist
        infoVC.artistImage = image
        infoVC.showPaintingInfo = true
        infoVC.modalPresentationStyle = .fullScreen
        
        present(infoVC, animated: true)
        print("✅ Painting InfoViewController presentato")
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print("🖼️ Immagine selezionata")
        picker.dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage else {
            print("❌ Errore caricamento immagine")
            resultLabel.text = "Error loading image"
            return
        }
        
        print("✅ Immagine caricata, inizio classificazione")
        imageView.image = image
        currentImage = image
        classifyImage(image)
    }
    
    func classifyImage(_ image: UIImage) {
        print("\n🧠 === INIZIO CLASSIFICAZIONE ===")
        resultLabel.text = "Classifying..."
        
        print("🔄 Nascondo bottoni all'inizio")
        artistInfoButton.isHidden = true
        paintingInfoButton.isHidden = true
        currentArtist = nil
        
        guard let resizedImage = image.resize(to: CGSize(width: 224, height: 224)),
              let pixelBuffer = resizedImage.toPixelBuffer() else {
            print("❌ Errore resize/pixelBuffer")
            resultLabel.text = "Error processing image"
            return
        }
        
        print("✅ Immagine preprocessata")
        
        do {
            let config = MLModelConfiguration()
            let model = try ArtClassifier_WORKING(configuration: config)
            
            guard let multiArray = pixelBuffer.toMLMultiArray() else {
                print("❌ Errore conversione MultiArray")
                resultLabel.text = "Error converting to MultiArray"
                return
            }
            
            print("✅ MultiArray creato")
            
            let input = ArtClassifier_WORKINGInput(input_1: multiArray)
            let output = try model.prediction(input: input)
            
            let probabilitiesDict = output.classLabel_probs
            let labels = ["altro", "chagall", "klimt", "monet", "picasso", "renoir", "van_gogh"]
            
            print("\n📊 DEBUG - PROBABILITIES:")
            var probs: [Double] = []
            for label in labels {
                let prob = probabilitiesDict[label] ?? 0.0
                probs.append(prob)
                print("  \(label): \(prob * 100)%")
            }
            
            guard let maxIndex = probs.enumerated().max(by: { $0.element < $1.element })?.offset else {
                print("❌ Impossibile trovare massimo")
                resultLabel.text = "Could not classify"
                return
            }
            
            let predictedClass = labels[maxIndex]
            let confidence = Int(probs[maxIndex] * 100)
            
            print("\n🎯 RISULTATO:")
            print("   Classe: \(predictedClass)")
            print("   Confidence: \(confidence)%")
            
            DispatchQueue.main.async {
                print("\n🔄 Entrato in DispatchQueue.main.async")
                
                let altroIndex = 0
                let altroProb = probs[altroIndex] * 100
                let maxProb = probs[maxIndex] * 100
                let vanGoghIndex = 6
                let vanGoghProb = probs[vanGoghIndex] * 100
                
                print("🔍 DEBUG ESTESO:")
                print("   altro: \(altroProb)%")
                print("   \(predictedClass): \(maxProb)%")
                print("   van_gogh: \(vanGoghProb)%")
                
                if predictedClass == "altro" || altroProb > 15 || confidence < 55 {
                    print("✅ ALTRO - autore non riconosciuto")
                    self.resultLabel.text = "Unknown artist\nnot recognized\n\nCould be :\n"
                    for i in 0..<7 {
                        if labels[i] != "altro" {
                            let conf = Int(probs[i] * 100)
                            self.resultLabel.text! += "\(labels[i].capitalized): \(conf)%\n"
                        }
                    }
                    print("   Bottoni NON mostrati")
                    
                } else {
                    print("✅ Riconosciuto: \(predictedClass)")
                    
                    var resultText = "\(predictedClass.capitalized)\n\(confidence)% confidence\n\n"
                    resultText += "Other predictions:\n"
                    for i in 0..<7 {
                        if i != maxIndex && labels[i] != "altro" {
                            let conf = Int(probs[i] * 100)
                            resultText += "\(labels[i].capitalized): \(conf)%\n"
                        }
                    }
                    self.resultLabel.text = resultText
                    
                    print("📝 Setting currentArtist = '\(predictedClass.capitalized)'")
                    self.currentArtist = predictedClass.capitalized
                    
                    self.artistInfoButton.isHidden = false
                    self.paintingInfoButton.isHidden = false
                    
                    self.view.setNeedsLayout()
                    self.view.layoutIfNeeded()
                    
                    print("✅ Bottoni visibili!")
                }
                
                print("🧠 === FINE CLASSIFICAZIONE ===\n")
            }
        } catch {
            print("❌ ERRORE CATCH: \(error)")
            resultLabel.text = "Error: \(error.localizedDescription)"
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("❌ ImagePicker annullato")
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

// MARK: - CVPixelBuffer to MLMultiArray
extension CVPixelBuffer {
    func toMLMultiArray() -> MLMultiArray? {
        guard let multiArray = try? MLMultiArray(shape: [1, 3, 224, 224], dataType: .float32) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(self, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(self, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(self) else {
            return nil
        }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(self)
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        let mean: [Float] = [0.485, 0.456, 0.406]
        let std: [Float] = [0.229, 0.224, 0.225]
        
        for y in 0..<224 {
            for x in 0..<224 {
                let pixelIndex = y * bytesPerRow + x * 4
                
                // ✅ FIX: ARGB format - Alpha(0), Red(1), Green(2), Blue(3)
                let r = Float(buffer[pixelIndex + 1]) / 255.0
                let g = Float(buffer[pixelIndex + 2]) / 255.0
                let b = Float(buffer[pixelIndex + 3]) / 255.0
                
                let rNorm = (r - mean[0]) / std[0]
                let gNorm = (g - mean[1]) / std[1]
                let bNorm = (b - mean[2]) / std[2]
                
                multiArray[[0, 0, y, x] as [NSNumber]] = NSNumber(value: rNorm)
                multiArray[[0, 1, y, x] as [NSNumber]] = NSNumber(value: gNorm)
                multiArray[[0, 2, y, x] as [NSNumber]] = NSNumber(value: bNorm)
            }
        }
        
        return multiArray
    }
}
