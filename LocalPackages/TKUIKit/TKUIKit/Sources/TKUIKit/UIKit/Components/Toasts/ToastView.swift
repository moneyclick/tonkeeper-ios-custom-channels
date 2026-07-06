import UIKit

public final class ToastView: TKPassthroughView, ConfigurableView {
    let titleLabel = UILabel()
    let activityView = TKLoaderView(size: .small, style: .primary)
    let iconView = UIImageView()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()

    // MARK: - Constraints

    private var topConstraint: NSLayoutConstraint?
    private var leftConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?
    private var rightConstraint: NSLayoutConstraint?

    // MARK: - Init

    init(model: Model) {
        self.model = model
        super.init(frame: .zero)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - ConfigurableView

    private let model: Model

    public struct Model: Equatable {
        public enum Shape {
            case rect
            case oval

            var height: CGFloat {
                switch self {
                case .rect: return 44
                case .oval: return 48
                }
            }

            var cornerRadius: CGFloat {
                switch self {
                case .rect: return 12
                case .oval: return 24
                }
            }

            var insets: UIEdgeInsets {
                switch self {
                case .rect: return .init(top: 12, left: 16, bottom: 12, right: 16)
                case .oval: return .init(top: 14, left: 24, bottom: 14, right: 24)
                }
            }

            func insets(hasIcon: Bool) -> UIEdgeInsets {
                switch (self, hasIcon) {
                case (.oval, true):
                    return .init(top: 14, left: 16, bottom: 14, right: 24)
                default:
                    return insets
                }
            }
        }

        let title: String
        let shape: Shape
        let isActivity: Bool
        let icon: UIImage?
        let iconTintColor: UIColor?
        let backgroundColor: UIColor
        let foregroundColor: UIColor

        init(
            title: String,
            shape: Shape,
            isActivity: Bool,
            icon: UIImage? = nil,
            iconTintColor: UIColor? = nil,
            backgroundColor: UIColor = .Background.contentTint,
            foregroundColor: UIColor = .Text.primary
        ) {
            self.title = title
            self.shape = shape
            self.isActivity = isActivity
            self.icon = icon
            self.iconTintColor = iconTintColor
            self.backgroundColor = backgroundColor
            self.foregroundColor = foregroundColor
        }
    }

    public func configure(model: Model) {
        layer.cornerRadius = model.shape.cornerRadius
        backgroundColor = model.backgroundColor
        layer.shadowColor = UIColor.black.withAlphaComponent(0.04).cgColor
        layer.shadowOpacity = 1
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
        titleLabel.attributedText = model.title
            .withTextStyle(
                .label2,
                color: model.foregroundColor,
                alignment: .center
            )

        if model.isActivity {
            activityView.isHidden = false
            activityView.startAnimation()
        } else {
            activityView.isHidden = true
            activityView.stopAnimation()
        }

        iconView.image = model.icon
        iconView.tintColor = model.iconTintColor
        iconView.isHidden = model.isActivity || model.icon == nil

        let insets = model.shape.insets(hasIcon: model.icon != nil && !model.isActivity)
        topConstraint?.constant = insets.top
        leftConstraint?.constant = insets.left
        bottomConstraint?.constant = -insets.bottom
        rightConstraint?.constant = -insets.right
    }

    // MARK: - Layout

    override public var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: model.shape.height)
    }
}

private extension ToastView {
    func setup() {
        titleLabel.numberOfLines = 0
        iconView.contentMode = .scaleAspectFit

        stackView.isUserInteractionEnabled = false
        addSubview(stackView)
        stackView.addArrangedSubview(iconView)
        stackView.addArrangedSubview(activityView)
        stackView.addArrangedSubview(titleLabel)

        setupConstraints()
        configure(model: model)
    }

    func setupConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false

        topConstraint = stackView.topAnchor.constraint(equalTo: topAnchor)
        leftConstraint = stackView.leftAnchor.constraint(equalTo: leftAnchor)
        bottomConstraint = stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        rightConstraint = stackView.rightAnchor.constraint(equalTo: rightAnchor)

        topConstraint?.isActive = true
        leftConstraint?.isActive = true
        bottomConstraint?.isActive = true
        rightConstraint?.isActive = true

        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),
        ])
    }
}
