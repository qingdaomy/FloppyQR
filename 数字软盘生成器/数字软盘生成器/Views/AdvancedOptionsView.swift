import SwiftUI

struct AdvancedOptionsView: View {
    @Binding var options: AdvancedOptions
    @ObservedObject private var lang = LanguageManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(L("advanced"), systemImage: "gearshape")
                .font(.headline)
            Toggle(L("strict_pair"), isOn: $options.strictPairing)
        }
    }
}
