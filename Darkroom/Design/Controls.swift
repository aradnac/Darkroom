//
//  Controls.swift
//  Darkroom
//
//  Small building blocks shared by every screen. Each one resolves through
//  `Theme`, so it dresses itself in whichever language is active.
//

import SwiftUI

struct OverlineText: View {
    let text: String
    var color: Color = Theme.inkSoft

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(2.4)
            .foregroundStyle(color)
    }
}

struct SegmentedPill<Value: Hashable>: View {
    let options: [Value]
    @Binding var selection: Value
    let title: (Value) -> String

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { option in
                segment(option)
            }
        }
        .padding(3)
        .background {
            Capsule().fill(Color.white.opacity(0.055))
        }
        .overlay {
            Capsule().strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        }
    }

    private func segment(_ option: Value) -> some View {
        let isOn = option == selection
        return Button {
            if selection != option {
                selection = option
            }
        } label: {
            Text(title(option))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isOn ? Theme.amberInk : Theme.inkSoft)
                .frame(minWidth: 26)
                .padding(.horizontal, 8)
                .frame(height: 30)
                .background {
                    if isOn {
                        Capsule().fill(Theme.amberGradient)
                    }
                }
        }
        .buttonStyle(HapticButtonStyle())
    }
}

struct CircleIconButton: View {
    let systemImage: String
    var size: CGFloat = 44
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .frame(width: size, height: size)
                .background {
                    Circle().fill(.ultraThinMaterial)
                    Circle().fill(Color.white.opacity(0.06))
                }
                .overlay {
                    Circle().strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                }
        }
        .buttonStyle(HapticButtonStyle())
    }
}

struct StatTile: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkFaint)
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.045))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        }
    }
}

/// The page a tab shows while its milestone is still ahead.
struct ComingNextView: View {
    let systemImage: String
    let headline: String
    let detail: String
    let bullets: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ZStack {
                Circle()
                    .fill(Theme.accentWash)
                    .frame(width: 76, height: 76)
                Circle()
                    .strokeBorder(Theme.hairline, lineWidth: 1)
                    .frame(width: 76, height: 76)
                Image(systemName: systemImage)
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(Theme.amber)
            }

            VStack(alignment: .leading, spacing: 10) {
                OverlineText(text: "Planned next", color: Theme.amber)
                Text(headline)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(bullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Theme.amber)
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)
                        Text(bullet)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.ink.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(radius: 28)
    }
}
