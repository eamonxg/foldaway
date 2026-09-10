import AppKit

final class SliderMenuItem: NSMenuItem {
    var onChange: (() -> Void)?
    var value: Double { slider.doubleValue }

    private let slider = NSSlider()
    private let valueLabel = NSTextField(labelWithString: "")
    private let format: String

    init(title: String, range: ClosedRange<Double>, value: Double, format: String) {
        self.format = format
        super.init(title: title, action: nil, keyEquivalent: "")
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 46))
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.menuFont(ofSize: NSFont.smallSystemFontSize)
        titleLabel.textColor = .secondaryLabelColor
        titleLabel.frame = NSRect(x: 14, y: 26, width: 150, height: 16)
        valueLabel.font = titleLabel.font
        valueLabel.textColor = .secondaryLabelColor
        valueLabel.alignment = .right
        valueLabel.frame = NSRect(x: 166, y: 26, width: 80, height: 16)
        slider.frame = NSRect(x: 12, y: 4, width: 236, height: 20)
        slider.minValue = range.lowerBound
        slider.maxValue = range.upperBound
        slider.doubleValue = value
        slider.isContinuous = true
        slider.target = self
        slider.action = #selector(sliderChanged)
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        container.addSubview(slider)
        view = container
        updateLabel()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func setValue(_ newValue: Double) {
        slider.doubleValue = newValue
        updateLabel()
    }

    @objc private func sliderChanged() {
        updateLabel()
        onChange?()
    }

    private func updateLabel() {
        valueLabel.stringValue = String(format: format, slider.doubleValue)
    }
}
