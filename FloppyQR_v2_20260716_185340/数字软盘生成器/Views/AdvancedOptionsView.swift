import SwiftUI

struct AdvancedOptionsView: View {
    @Binding var options: AdvancedOptions
    @State private var expanded = false

    var body: some View {
        DisclosureGroup(
            isExpanded: $expanded,
            content: {
                VStack(spacing: 10) {
                    Toggle("严格配对（启动头与数据盘 ID 匹配）", isOn: $options.strictPairing)

                    HStack {
                        Text("每通道位数:")
                        Picker("", selection: $options.bitsPerChannel) {
                            ForEach(options.bitsRange, id: \.self) { bits in
                                Text("\(bits) bit → \(capacityText(bits))")
                            }
                        }
                        .labelsHidden()
                        .frame(width: 200)
                        Spacer()
                    }
                }
                .padding(.top, 6)
            },
            label: {
                Label("高级选项", systemImage: "gearshape")
                    .font(.headline)
            }
        )
    }

    private func capacityText(_ bits: Int) -> String {
        let bytes = 1024 * 1024 * 4 * bits / 8
        if bytes >= 1024 * 1024 {
            return "\(bytes / 1024 / 1024) MB"
        } else {
            return "\(bytes / 1024) KB"
        }
    }
}
