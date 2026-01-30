import UIKit
import AVFoundation
import CoreML

class CameraViewController: UIViewController {
    
    // Camera
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?
    
    // UI Elements
    private let previewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let captureButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.layer.cornerRadius = 40
        button.layer.borderWidth = 5
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("✕", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 30, weight: .bold)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Inquadra il quadro e scatta"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Result View
    private let resultView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let resultImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let resultLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let confidenceLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let retakeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Torna al menu", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupUI()
        setupCamera()
        setupActions()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = previewContainer.bounds
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.addSubview(previewContainer)
        view.addSubview(instructionLabel)
        view.addSubview(captureButton)
        view.addSubview(closeButton)
        view.addSubview(resultView)
        view.addSubview(activityIndicator)
        
        resultView.addSubview(resultImageView)
        resultView.addSubview(resultLabel)
        resultView.addSubview(confidenceLabel)
        resultView.addSubview(retakeButton)
        
        NSLayoutConstraint.activate([
            previewContainer.topAnchor.constraint(equalTo: view.topAnchor),
            previewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            instructionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            instructionLabel.heightAnchor.constraint(equalToConstant: 50),
            
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            captureButton.widthAnchor.constraint(equalToConstant: 80),
            captureButton.heightAnchor.constraint(equalToConstant: 80),
            
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 50),
            closeButton.heightAnchor.constraint(equalToConstant: 50),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            resultView.topAnchor.constraint(equalTo: view.topAnchor),
            resultView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            resultView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            resultView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            resultImageView.topAnchor.constraint(equalTo: resultView.safeAreaLayoutGuide.topAnchor, constant: 40),
            resultImageView.leadingAnchor.constraint(equalTo: resultView.leadingAnchor, constant: 40),
            resultImageView.trailingAnchor.constraint(equalTo: resultView.trailingAnchor, constant: -40),
            resultImageView.heightAnchor.constraint(equalTo: resultView.heightAnchor, multiplier: 0.4),
            
            resultLabel.topAnchor.constraint(equalTo: resultImageView.bottomAnchor, constant: 30),
            resultLabel.leadingAnchor.constraint(equalTo: resultView.leadingAnchor, constant: 20),
            resultLabel.trailingAnchor.constraint(equalTo: resultView.trailingAnchor, constant: -20),
            
            confidenceLabel.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 20),
            confidenceLabel.leadingAnchor.constraint(equalTo: resultView.leadingAnchor, constant: 20),
            confidenceLabel.trailingAnchor.constraint(equalTo: resultView.trailingAnchor, constant: -20),
            
            retakeButton.bottomAnchor.constraint(equalTo: resultView.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            retakeButton.centerXAnchor.constraint(equalTo: resultView.centerXAnchor),
            retakeButton.widthAnchor.constraint(equalToConstant: 250),
            retakeButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        
        guard let captureSession = captureSession,
              let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            showAlert(title: "Errore", message: "Camera non disponibile")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            photoOutput = AVCapturePhotoOutput()
            
            if let photoOutput = photoOutput, captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
            previewLayer?.frame = previewContainer.bounds
            
            if let previewLayer = previewLayer {
                previewContainer.layer.addSublayer(previewLayer)
            }
            
        } catch {
            showAlert(title: "Errore", message: "Impossibile configurare la camera: \(error.localizedDescription)")
        }
    }
    
    private func setupActions() {
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        retakeButton.addTarget(self, action: #selector(retakeTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
        
        UIView.animate(withDuration: 0.1, animations: {
            self.previewContainer.alpha = 0.5
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.previewContainer.alpha = 1.0
            }
        }
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func retakeTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - Classification with Manual Preprocessing
    
    private func classifyImage(_ image: UIImage) {
        activityIndicator.startAnimating()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Resize
            guard let resizedImage = self.resizeImage(image, targetSize: CGSize(width: 224, height: 224)) else {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.showAlert(title: "Errore", message: "Impossibile processare l'immagine")
                }
                return
            }
            
            // Preprocess con normalizzazione ImageNet
            guard let inputArray = self.preprocessImage(resizedImage) else {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.showAlert(title: "Errore", message: "Errore nel preprocessing")
                }
                return
            }
            
            do {
                let config = MLModelConfiguration()
                let model = try ArtClassifier_WORKING(configuration: config)
                
                let input = ArtClassifier_WORKINGInput(input_1: inputArray)
                let output = try model.prediction(input: input)
                
                let probabilities = output.classLabel_probs
                let sortedProbs = probabilities.sorted { $0.value > $1.value }
                
                guard let topResult = sortedProbs.first else {
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.showAlert(title: "Errore", message: "Impossibile classificare")
                    }
                    return
                }
                
                let predictedClass = topResult.key
                let confidence = topResult.value * 100
                
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.showResult(image: image, artist: predictedClass, confidence: confidence, sortedProbs: sortedProbs)
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.showAlert(title: "Errore", message: "Errore: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // PREPROCESSING MANUALE
    private func preprocessImage(_ image: UIImage) -> MLMultiArray? {
        let width = 224
        let height = 224
        
        let mean: [Float] = [0.485, 0.456, 0.406]
        let std: [Float] = [0.229, 0.224, 0.225]
        
        guard let multiArray = try? MLMultiArray(shape: [1, 3, 224, 224], dataType: .float32) else {
            return nil
        }
        
        // Create RGB context (NOT BGRA!)
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bitsPerComponent = 8
        
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            return nil
        }
        
        // Allocate pixel buffer
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            return nil
        }
        
        // Draw image into RGB context
        guard let cgImage = image.cgImage else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Process pixels (now in RGB format!)
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (y * width + x) * bytesPerPixel
                
                // Get RGB values (0-255) - NOW CORRECT ORDER!
                let r = Float(pixelData[pixelIndex]) / 255.0
                let g = Float(pixelData[pixelIndex + 1]) / 255.0
                let b = Float(pixelData[pixelIndex + 2]) / 255.0
                
                let rNorm = (r - mean[0]) / std[0]
                let gNorm = (g - mean[1]) / std[1]
                let bNorm = (b - mean[2]) / std[2]
                
                let rIndex = [0, 0, y, x] as [NSNumber]
                let gIndex = [0, 1, y, x] as [NSNumber]
                let bIndex = [0, 2, y, x] as [NSNumber]
                
                multiArray[rIndex] = NSNumber(value: rNorm)
                multiArray[gIndex] = NSNumber(value: gNorm)
                multiArray[bIndex] = NSNumber(value: bNorm)
            }
        }
        
        return multiArray
    }
    
    // MARK: - Result Display
    
    private func showResult(image: UIImage, artist: String, confidence: Double, sortedProbs: [(key: String, value: Double)]) {
        resultImageView.image = image
        
        if confidence < 55 {
            resultLabel.text = "⚠️ Bassa confidenza"
            var detailText = "Potrebbe essere:\n"
            for (label, prob) in sortedProbs.prefix(5) {
                let conf = Int(prob * 100)
                if conf > 5 {
                    detailText += String(format: "%@: %d%%\n", label.capitalized, conf)
                }
            }
            confidenceLabel.text = detailText
        } else {
            resultLabel.text = "🎨 \(artist.capitalized)"
            
            var detailText = String(format: "Confidenza: %.1f%%\n\n", confidence)
            detailText += "Altri risultati:\n"
            
            for (label, prob) in sortedProbs.dropFirst().prefix(3) {
                if prob > 0.01 {
                    detailText += String(format: "%@: %.1f%%\n", label.capitalized, prob * 100)
                }
            }
            confidenceLabel.text = detailText
        }
        
        showResultView()
    }
    
    private func showResultView() {
        resultView.alpha = 0
        resultView.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.resultView.alpha = 1
        }
    }
    
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    // MARK: - Utilities
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            showAlert(title: "Errore", message: "Errore durante la cattura: \(error.localizedDescription)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            showAlert(title: "Errore", message: "Impossibile ottenere l'immagine")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
        
        classifyImage(image)
    }
}
