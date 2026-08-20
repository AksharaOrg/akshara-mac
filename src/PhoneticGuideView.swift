import SwiftUI

@available(macOS 11.0, *)
struct PhoneticGuideView: View {
    let isSmart: Bool
    var onDismiss: (() -> Void)?

    private var modeName: String { isSmart ? "Smart Phonetic" : "Phonetic" }

    var body: some View {
        VStack(spacing: 0) {
            header
            
            ScrollView {
                if isSmart {
                    SmartPhoneticContent()
                } else {
                    NormalPhoneticContent()
                }
            }
            
            footer
        }
        .frame(width: 520, height: isSmart ? 600 : 540)
        .background(windowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .edgesIgnoringSafeArea(.all)
    }

    @ViewBuilder
    private var windowBackground: some View {
        if #available(macOS 26.0, *) {
            GlassEffectBackground()
        } else {
            VisualEffectBackground()
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "text.cursor")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(modeName) Typing")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(isSmart ? "Comprehensive guide for Smart Phonetic typing." : "Write Sinhala by typing the sound with familiar Roman letters.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 12)
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button(action: {
                onDismiss?()
            }) {
                Text("Close")
                    .frame(minWidth: 60)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .padding(.top, 12)
    }
}

@available(macOS 11.0, *)
struct NormalPhoneticContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            CollapsibleGuideSection(title: "ස්වර අක්ෂර යතුරුකරන ආකාරය") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("සාමාන්‍ය ශබ්දානුකූල ඉංග්‍රීසි අකුරු වලින් ලිවිය හැක. දීර්ඝ කිරීමකදී එකම ඉංග්‍රීසි අකුර දෙවරක් යෙදේ.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    ExampleGrid(rows: [
                        ("a", "අ"), ("aa", "ආ"),
                        ("ae", "ඇ"), ("aee", "ඈ"),
                        ("i", "ඉ"), ("ii", "ඊ"),
                        ("u", "උ"), ("uu", "ඌ"),
                        ("e", "එ"), ("ee", "ඒ"),
                        ("ai", "ඓ"),
                        ("o", "ඔ"), ("oo", "ඕ"),
                        ("au", "ඖ")
                    ], columns: 2)
                }
            }
            
            CollapsibleGuideSection(title: "ව්‍යංජන අක්ෂර යතුරුකරන ආකාරය") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("සාමාන්‍ය ශබ්දානුකූල ඉංග්‍රීසි අකුරු වලින් ලිවිය හැක. මූර්ධජ අකුරු ලිවීම සඳහා ශබ්දානුකූල ඉංග්‍රීසි අකුරේ කැපිටල් අකුරු භාවිතා කෙරේ.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    ExampleGrid(rows: [
                        ("ka", "ක"), ("ga", "ග"),
                        ("cha", "ච"), ("ja", "ජ"),
                        ("ta", "ට"), ("da", "ඩ"),
                        ("tha", "ත"), ("dh", "ද"),
                        ("na", "න"), ("Na", "ණ"),
                        ("pa", "ප"), ("ba", "බ"),
                        ("ma", "ම"), ("ya", "ය"),
                        ("ra", "ර"), ("la", "ල"),
                        ("La", "ළ"), ("wa / va", "ව"),
                        ("sa", "ස"), ("sha", "ශ"),
                        ("Sh", "ෂ"), ("ha", "හ"),
                        ("fa", "ෆ")
                    ], columns: 3)
                }
            }
            
            CollapsibleGuideSection(title: "මහප්‍රාණ අක්ෂර යතුරුකරන ආකාරය") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("සාමාන්‍ය ශබ්දානුකූල ඉංග්‍රීසි අකුරක් සමඟ h අකුරක් යොදා මහප්‍රාණ අක්ෂර යතුරු කළ හැක. ඨ, ඪ, ඡ ආදිය සඳහා කැපිටල් අකුරු භාවිතා කෙරේ.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    ExampleGrid(rows: [
                        ("kh", "ඛ"), ("gh", "ඝ"),
                        ("C", "ඡ"), ("jh", "ඣ"),
                        ("Th", "ඨ"), ("Dh", "ඪ"),
                        ("ph", "ඵ"), ("bh", "භ")
                    ], columns: 2)
                }
            }
            
            CollapsibleGuideSection(title: "සඤ්ඤක අක්ෂර යතුරුකරන ආකාරය") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("සඤ්ඤක අකුරු සඳහා පහත සංයෝජන භාවිතා වේ.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    ExampleGrid(rows: [
                        ("nnga", "ඟ"), ("nnja", "ඦ"),
                        ("nnda", "ඬ"), ("nndha / nnqa", "ඳ"),
                        ("nnka", "ඤ"), ("nnha", "ඥ"),
                        ("Ba", "ඹ")
                    ], columns: 2)
                }
            }
            
            CollapsibleGuideSection(title: "වෙනත් අක්ෂර යතුරුකරන ආකාරය") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("විශේෂ ශබ්ද සඳහා පහත අකුරු සංයෝජන භාවිතා වේ.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    ExampleGrid(rows: [
                        ("ng", "ඞ"), ("gn", "ඥ"),
                        ("ny", "ඤ"), ("M", "ං"),
                        ("H", "ඃ")
                    ], columns: 2)
                }
            }
            
            CollapsibleGuideSection(title: "පිළි සමඟ ව්‍යංජන අක්ෂර යතුරුකරන ආකාරය") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("සාමාන්‍ය ශබ්දානුකූල ඉංග්‍රීසි අකුරු සංයෝජනයෙන් යතුරු කළ හැක.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    ExampleGrid(rows: [
                        ("k", "ක්"), ("ka", "ක"),
                        ("kaa", "කා"), ("kae", "කැ"),
                        ("kaee", "කෑ"), ("ki", "කි"),
                        ("kii", "කී"), ("ku", "කු"),
                        ("kuu", "කූ"), ("ke", "කෙ"),
                        ("kee", "කේ"), ("kai", "කෛ"),
                        ("ko", "කො"), ("koo", "කෝ"),
                        ("kau", "කෞ"), ("kH", "කඃ"),
                        ("kM", "කං"), ("kya", "ක්‍ය"),
                        ("kra", "ක්‍ර")
                    ], columns: 2)
                }
            }
            
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
}

@available(macOS 11.0, *)
struct SmartPhoneticContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            CollapsibleGuideSection(title: "ස්වර අක්ෂර යතුරුකරන ආකාරය") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("සාමාන්‍ය ශබ්දානුකූල ඉංග්‍රීසි අකුරු වලින් ලිවිය හැක. දීර්ඝ කිරීමකදී එකම ඉංග්‍රීසි අකුර දෙවරක් යෙදේ. ‘ඇ’ සහ ‘ඍ’ සඳහා පමණක් ඉංග්‍රීසි කැපිටල් අකුරු යෙදේ.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    ExampleGrid(rows: [
                        ("a", "අ"), ("aa", "ආ"),
                        ("A", "ඇ"), ("Aa / AA", "ඈ"),
                        ("i", "ඉ"), ("ii", "ඊ"),
                        ("u", "උ"), ("uu", "ඌ"),
                        ("R", "ඍ"), ("Ru", "ඎ"),
                        ("e", "එ"), ("ee", "ඒ"),
                        ("ai", "ඓ"),
                        ("o", "ඔ"), ("oo", "ඕ"),
                        ("au / ou", "ඖ")
                    ], columns: 2)
                }
            }
            
            CollapsibleGuideSection(title: "ව්‍යංජන අක්ෂර යතුරුකරන ආකාරය") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("සාමාන්‍ය ශබ්දානුකූල ඉංග්‍රීසි අකුරු වලින් ලිවිය හැක. මූර්ධජ අකුරු ලිවීම සඳහා ශබ්දානුකූල ඉංග්‍රීසි අකුරේ කැපිටල් අකුරු භාවිතා කෙරේ. ’ද’ සඳහා පමණක් dha හෝ q යෙදේ.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    ExampleGrid(rows: [
                        ("ka", "ක"), ("ga", "ග"),
                        ("cha", "ච"), ("ja", "ජ"),
                        ("ta", "ට"), ("da", "ඩ"),
                        ("tha", "ත"), ("dha / qa", "ද"),
                        ("na", "න"), ("Na", "ණ"),
                        ("pa", "ප"), ("ba", "බ"),
                        ("ma", "ම"), ("ya", "ය"),
                        ("ra", "ර"), ("la", "ල"),
                        ("La", "ළ"), ("wa / va", "ව"),
                        ("sa", "ස"), ("sha", "ශ"),
                        ("Sa / Sha", "ෂ"), ("ha", "හ"),
                        ("fa", "ෆ")
                    ], columns: 3)
                }
            }
            
            CollapsibleGuideSection(title: "මහප්‍රාණ අක්ෂර යතුරුකරන ආකාරය") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("සාමාන්‍ය ශබ්දානුකූල ඉංග්‍රීසි අකුරක් සමඟ h අකුරක් යොදා මහප්‍රාණ අක්ෂර යතුරු කළ හැක. ‘ඨ’ සහ ‘ඪ’ පමණක් ශබ්දානුකූ ඉංග්‍රීසි අකුරේ කැපිටල් අකුරු භාවිතා කෙරේ.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    ExampleGrid(rows: [
                        ("kha", "ඛ"), ("gha", "ඝ"),
                        ("chha", "ඡ"), ("Ta", "ඨ"),
                        ("Da", "ඪ"), ("thha", "ථ"),
                        ("dhha", "ධ"), ("pha", "ඵ"),
                        ("bha", "භ")
                    ], columns: 2)
                }
            }
            
            CollapsibleGuideSection(title: "සඤ්ඤක සහ වෙනත් අක්ෂර") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("සාමාන්‍ය ශබ්දානුකූල ඉංග්‍රීසි අකුර ඉදිරියට z අකුරක් යොදා සඤ්ඤක අක්ෂර යතුරු කළ හැක. ‘ඹ' සඳහා පමණක් කැපිටල් B යෙදේ.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    ExampleGrid(rows: [
                        ("zga", "ඟ"), ("zja", "ඦ"),
                        ("zda", "ඬ"), ("zdha, zqa", "ඳ"),
                        ("zka", "ඤ"), ("zha", "ඥ"),
                        ("Ba", "ඹ"), ("Lu", "ළු")
                    ], columns: 2)
                }
            }
            
            CollapsibleGuideSection(title: "පිළි සමඟ ව්‍යංජන අක්ෂර යතුරුකරන ආකාරය") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("සාමාන්‍ය ශබ්දානුකූල ඉංග්‍රීසි අකුරු සංයෝජනයෙන් යතුරු කළ හැක. දීර්ඝ පිළි යෙදීමේදී එකම ඉංග්‍රීසි අකුර දෙවරක් යෙදේ. ‘ැ’ සඳහා පමණක් ඉංග්‍රීසි කැපිටල් අකුරු A යෙදේ.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    ExampleGrid(rows: [
                        ("k", "ක්"), ("ka", "ක"),
                        ("kaa", "කා"), ("kA", "කැ"),
                        ("kAa / kAA", "කෑ"), ("ki", "කි"),
                        ("kii", "කී"), ("ku", "කු"),
                        ("kuu", "කූ"), ("kru", "කෘ"),
                        ("kruu", "කෲ"), ("ke", "කෙ"),
                        ("kee", "කේ"), ("kai", "කෛ"),
                        ("ko", "කො"), ("koo", "කෝ"),
                        ("kau", "කෞ"), ("kaH", "කඃ"),
                        ("kax / kazn", "කං"), ("kaX", "කඞ"),
                        ("kya", "ක්‍ය"), ("kra", "ක්‍ර")
                    ], columns: 2)
                }
            }
            
            CollapsibleGuideSection(title: "බැඳි අක්ෂර යතුරු කරන ආකාරය") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("ශබ්දානුකූල ක්‍රමයෙන් බැඳි අක්ෂර ලිවිය නොහැකි නමුත් විජේසේකර ක්‍රමයෙන් බැඳි අක්ෂර ලිවිය හැක.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
}

@available(macOS 11.0, *)
struct GuideSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    @Environment(\.colorScheme) private var colorScheme

    private var cardBackground: Color {
        colorScheme == .dark
            ? Color(NSColor.controlBackgroundColor).opacity(0.55)
            : Color(white: 0.93)
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.07) : Color.black.opacity(0.12)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(cardBackground)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: colorScheme == .dark ? .clear : Color.black.opacity(0.07), radius: 4, x: 0, y: 2)
    }
}

class ExpandState: ObservableObject {
    @Published var isExpanded: Bool = false
}

@available(macOS 11.0, *)
struct CollapsibleGuideSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    @StateObject private var expandState = ExpandState()
    @Environment(\.colorScheme) private var colorScheme

    private var cardBackground: Color {
        colorScheme == .dark
            ? Color(NSColor.controlBackgroundColor).opacity(0.55)
            : Color(white: 0.93)
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.07) : Color.black.opacity(0.12)
    }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                expandState.isExpanded.toggle()
            }
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Header — always visible
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(expandState.isExpanded ? 90 : 0))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: expandState.isExpanded)
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                }

                // Expandable content
                if expandState.isExpanded {
                    VStack(alignment: .leading, spacing: 14) {
                        Divider().padding(.vertical, 4)
                        content
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(cardBackground)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: colorScheme == .dark ? .clear : Color.black.opacity(0.07), radius: 4, x: 0, y: 2)
    }
}

@available(macOS 11.0, *)
private struct ExampleGrid: View {
    let rows: [(String, String)]
    var columns: Int = 3

    var body: some View {
        let gridItems = Array(repeating: GridItem(.flexible()), count: columns)
        
        LazyVGrid(columns: gridItems, spacing: 8) {
            ForEach(rows, id: \.0) { input, output in
                HStack(spacing: 7) {
                    Text(input)
                        .font(.system(.body, design: .monospaced))
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(output)
                        .font(.body.weight(.medium))
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
        }
    }
}

@available(macOS 11.0, *)
private struct GuidePattern: View {
    let input: String
    let output: String
    let note: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(input)
                .font(.system(.body, design: .monospaced).weight(.medium))
                .frame(width: 86, alignment: .leading)
            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(output)
                .font(.body.weight(.medium))
                .frame(width: 42, alignment: .leading)
            Text(note)
                .font(.callout)
                .foregroundColor(.secondary)
        }
    }
}
