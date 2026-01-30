import UIKit

class ArtistInfoViewController: UIViewController {
    
    var artistName: String = ""
    var artistImage: UIImage?
    var showPaintingInfo: Bool = false
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = 12
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let infoTextView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.isEditable = false
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("✕", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 28, weight: .bold)
        button.tintColor = .label
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.99, green: 0.97, blue: 0.90, alpha: 1.0)
        setupUI()
        loadInfo()
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(closeButton)
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(infoTextView)
        contentView.addSubview(loadingIndicator)
        
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
            
            closeButton.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            imageView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalToConstant: 250),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            infoTextView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            infoTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            infoTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            infoTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        
        if let image = artistImage {
            imageView.image = image
        }
    }
    
    private func loadInfo() {
        titleLabel.text = artistName
        infoTextView.text = "Loading..."
        loadingIndicator.startAnimating()
        
        if showPaintingInfo, let image = artistImage {
            GeminiProvider.shared.identifyPainting(image: image, artistName: artistName) { [weak self] result in
                DispatchQueue.main.async {
                    self?.loadingIndicator.stopAnimating()
                    switch result {
                    case .success(let info):
                        self?.displayPaintingInfo(info)
                    case .failure(let error):
                        self?.infoTextView.text = "Errore: \(error.localizedDescription)"
                    }
                }
            }
        } else {
            GeminiProvider.shared.getArtistInfo(artistName: artistName) { [weak self] result in
                DispatchQueue.main.async {
                    self?.loadingIndicator.stopAnimating()
                    switch result {
                    case .success(let info):
                        self?.displayArtistInfo(info)
                    case .failure(let error):
                        self?.infoTextView.text = "Errore: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    private func displayArtistInfo(_ info: ArtistInfo) {
        let regularFont = UIFont.systemFont(ofSize: 17, weight: .regular)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.alignment = .natural
        
        let attributedText = NSAttributedString(
            string: info.biography,
            attributes: [
                .font: regularFont,
                .paragraphStyle: paragraphStyle
            ]
        )
        
        infoTextView.attributedText = attributedText
    }
    
    private func displayPaintingInfo(_ info: PaintingInfo) {
        titleLabel.text = info.title
        
        let regularFont = UIFont.systemFont(ofSize: 17, weight: .regular)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.alignment = .natural
        
        let attributedText = NSAttributedString(
            string: info.description,
            attributes: [
                .font: regularFont,
                .paragraphStyle: paragraphStyle
            ]
        )
        
        infoTextView.attributedText = attributedText
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
