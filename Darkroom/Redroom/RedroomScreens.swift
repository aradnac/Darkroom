//
//  RedroomScreens.swift
//  Darkroom
//
//  The room's furniture: the panel a group of values is mounted on, the row a
//  single value is engraved on, the chip, the warning and the note. Every screen
//  in REDROOM is assembled from these, so a value reads the same way whether it
//  is on the setup bench, a bottle's card or a tool.
//
//  A warning is never colour alone: it is an icon, a word and a line of text,
//  always in that order.
//

import SwiftUI

// MARK: - Panel

/// A group of controls or values on smoked glass, with an optional heading.
struct RedroomPanel<Content: View>: View {
    var title: String?
    var detail: String?
    var variant: RedroomGlassVariant = .smoked
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                RedroomSectionHeader(title: title)
            }

            if let detail {
                Text(detail)
                    .font(Redroom.body(12))
                    .foregroundStyle(Redroom.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .redroomGlass(variant: variant, cornerRadius: RedroomMetrics.cardRadius)
    }
}

// MARK: - Rows

/// Label on the left, figure on the right. The figure is always monospaced, so
/// a column of them lines up like a table of exposures.
struct RedroomValueRow: View {
    let label: String
    let value: String
    var emphasised: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label)
                .font(Redroom.body(14))
                .foregroundStyle(Redroom.textMuted)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            Text(value)
                .font(Redroom.figure(15, weight: .semibold))
                .foregroundStyle(emphasised ? Redroom.safelight : Redroom.text)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}

/// A row that leads somewhere: the title, the line under it, and the gate mark.
struct RedroomNavRow: View {
    let title: String
    let detail: String
    var symbol: String?
    var badge: String?

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Redroom.safelight)
                    .frame(width: 30, height: 30)
                    .background {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Redroom.deepRed.opacity(0.5))
                    }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Redroom.body(15, weight: .semibold))
                    .foregroundStyle(Redroom.text)
                    .multilineTextAlignment(.leading)

                Text(detail)
                    .font(Redroom.body(12))
                    .foregroundStyle(Redroom.textMuted)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 6)

            if let badge {
                RedroomChip(text: badge)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Redroom.textMuted)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Chip

/// A stamped plate: the value, boxed, in the room's own metal.
struct RedroomChip: View {
    let text: String
    var emphasised: Bool = false

    var body: some View {
        Text(text.uppercased())
            .font(Redroom.label(9))
            .tracking(0.8)
            .foregroundStyle(emphasised ? Redroom.text : Redroom.textMuted)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule()
                    .fill(emphasised ? Redroom.deepRed.opacity(0.75) : Redroom.color(0x140808))
            }
            .overlay {
                Capsule().strokeBorder(
                    emphasised ? Redroom.safelight.opacity(0.55) : Redroom.textDisabled.opacity(0.5),
                    lineWidth: 1
                )
            }
    }
}

// MARK: - Warning and note

/// A warning, with its icon and its words. The icon and the heading carry the
/// meaning; the red only agrees with them.
struct RedroomWarning: View {
    let title: String
    var detail: String?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Redroom.safelight)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Redroom.body(13, weight: .semibold))
                    .foregroundStyle(Redroom.text)

                if let detail {
                    Text(detail)
                        .font(Redroom.body(12))
                        .foregroundStyle(Redroom.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Redroom.deepRed.opacity(0.35))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Redroom.safelight.opacity(0.5), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Warning. \(title)")
    }
}

/// An ordinary note: the room's quiet voice, never red.
struct RedroomNote: View {
    let text: String
    var symbol: String = "info.circle"

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Redroom.textMuted)
                .padding(.top, 2)

            Text(text)
                .font(Redroom.body(12))
                .foregroundStyle(Redroom.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Empty state

/// Nothing on the bench yet, said plainly, with what would fill it.
struct RedroomEmptyState: View {
    let title: String
    let detail: String
    var symbol: String = "tray"

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(Redroom.textMuted)

            Text(title)
                .font(Redroom.body(16, weight: .semibold))
                .foregroundStyle(Redroom.text)

            Text(detail)
                .font(Redroom.body(13))
                .foregroundStyle(Redroom.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .redroomGlass(variant: .smoked, cornerRadius: RedroomMetrics.cardRadius)
    }
}

// MARK: - Segmented choice

/// The room's segmented control: a row of stamped keys, the chosen one lit from
/// the safelight rather than filled with an accent.
struct RedroomSegmented<Item: Hashable>: View {
    let items: [Item]
    @Binding var selection: Item
    let title: (Item) -> String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items, id: \.self) { item in
                let isOn = item == selection

                Button {
                    Haptics.impact(.light)
                    withAnimation(.snappy(duration: 0.26)) {
                        selection = item
                    }
                } label: {
                    Text(title(item).uppercased())
                        .font(Redroom.label(10))
                        .tracking(0.8)
                        .foregroundStyle(isOn ? Redroom.text : Redroom.textMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background {
                            if isOn {
                                Color.clear.redroomGlass(variant: .optical, cornerRadius: 11)
                            } else {
                                Color.clear
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(HapticButtonStyle())
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Redroom.color(0x0A0404))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Redroom.textDisabled.opacity(0.4), lineWidth: 1)
        }
    }
}

// MARK: - Stepper

/// A bench stepper: the label, the figure, and two machined keys.
struct RedroomStepper: View {
    let title: String
    let value: String
    var decrement: (() -> Void)?
    var increment: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(Redroom.body(14))
                .foregroundStyle(Redroom.textMuted)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 6)

            Text(value)
                .font(Redroom.figure(16, weight: .semibold))
                .foregroundStyle(Redroom.text)
                .contentTransition(.numericText())

            stepKey("minus", label: "Decrease \(title)", action: decrement)
            stepKey("plus", label: "Increase \(title)", action: increment)
        }
        .accessibilityElement(children: .contain)
    }

    private func stepKey(_ symbol: String, label: String, action: (() -> Void)?) -> some View {
        Button {
            action?()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(action == nil ? Redroom.textDisabled : Redroom.text)
                .frame(width: 36, height: 34)
                .background {
                    Color.clear.redroomGlass(variant: .transparent, cornerRadius: 10)
                }
        }
        .buttonStyle(HapticButtonStyle())
        .disabled(action == nil)
        .accessibilityLabel(label)
    }
}

// MARK: - Sheet body

/// The body every REDROOM sheet uses: the room, the scroll, and the sheet's
/// own header, with the content arriving on the enlarger's shutter.
struct RedroomSheetBody<Content: View>: View {
    let kicker: String
    let title: String
    var detail: String?
    var confirmTitle: String?
    var onConfirm: (() -> Void)?
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                content()
            }
            .padding(.horizontal, RedroomMetrics.screenPadding)
            .padding(.bottom, 28)
            .redroomReveal(.shutter)
        }
        .scrollIndicators(.hidden)
        .background(Redroom.background)
        .safeAreaInset(edge: .top, spacing: 0) {
            RedroomSheetHeader(
                kicker: kicker,
                title: title,
                detail: detail,
                confirmTitle: confirmTitle,
                onConfirm: onConfirm
            )
            .background(Redroom.background)
        }
        .redroomSheet()
    }
}
