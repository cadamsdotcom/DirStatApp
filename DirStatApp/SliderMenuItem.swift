import AppKit

class SliderMenuItem: NSView {
    private let slider: NSSlider
    private let label: NSTextField
    var onValueChanged: ((Double) -> Void)?

    init(initialValue: Double) {
        slider = NSSlider(value: initialValue, minValue: 0.1, maxValue: 1.0, target: nil, action: nil)
        label = NSTextField(labelWithString: "\(Int(initialValue * 100))%")

        super.init(frame: NSRect(x: 0, y: 0, width: 200, height: 28))

        slider.target = self
        slider.action = #selector(sliderChanged)
        slider.isContinuous = true

        label.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        label.alignment = .right

        slider.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        addSubview(slider)
        addSubview(label)

        NSLayoutConstraint.activate([
            slider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            slider.centerYAnchor.constraint(equalTo: centerYAnchor),
            slider.widthAnchor.constraint(equalToConstant: 130),

            label.leadingAnchor.constraint(equalTo: slider.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.widthAnchor.constraint(equalToConstant: 36),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    @objc private func sliderChanged() {
        let value = slider.doubleValue
        label.stringValue = "\(Int(value * 100))%"
        onValueChanged?(value)
    }
}
