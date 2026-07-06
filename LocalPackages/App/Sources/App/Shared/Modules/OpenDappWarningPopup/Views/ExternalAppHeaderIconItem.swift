import TKCore
import TKUIKit
import UIKit

struct ExternalAppHeaderIconItem: TKPopUp.Item {
    let bottomSpace: CGFloat
    private let imageURL: URL?
    private let image: UIImage?

    init(bottomSpace: CGFloat, imageURL: URL) {
        self.bottomSpace = bottomSpace
        self.imageURL = imageURL
        image = nil
    }

    init(bottomSpace: CGFloat, image: UIImage?) {
        self.bottomSpace = bottomSpace
        imageURL = nil
        self.image = image
    }

    func getView() -> UIView {
        return ExternalAppHeaderIconView(imageURL: imageURL, image: image)
    }
}

private final class ExternalAppHeaderIconView: UIView {
    private let imageView = UIImageView()
    private let imageLoader = ImageLoader()

    init(imageURL: URL?, image: UIImage?) {
        super.init(frame: .zero)
        setup(imageURL: imageURL, image: image)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup(imageURL: URL?, image: UIImage?) {
        imageView.layer.cornerRadius = 20
        imageView.layer.cornerCurve = .continuous
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .Background.content
        imageView.image = image
        if let imageURL {
            _ = imageLoader.loadImage(url: imageURL, imageView: imageView)
        }

        addSubview(imageView)

        imageView.snp.makeConstraints { make in
            make.top.bottom.equalTo(self)
            make.centerX.equalTo(self)
            make.width.height.equalTo(72)
        }
    }
}
