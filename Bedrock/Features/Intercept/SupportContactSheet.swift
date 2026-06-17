import SwiftUI
import ContactsUI

/// Sets the person the user calls in a hard moment (§4). Either pick from the
/// system Contacts picker — which runs out-of-process and needs NO Contacts
/// permission — or type a name and number by hand. Stored on-device only.
struct SupportContactSheet: View {
    @Environment(AppServices.self) private var services
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var phone = ""
    @State private var showingPicker = false

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        phone.filter(\.isNumber).count >= 3
    }

    var body: some View {
        NavigationStack {
            ZStack {
                StoneBackground()
                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        header

                        Button {
                            showingPicker = true
                        } label: {
                            Label("Choose from Contacts", systemImage: "person.crop.circle.badge.plus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bedrockGlass)

                        Text("or enter it yourself")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.textSecondary)

                        GlassCard {
                            VStack(spacing: Theme.Spacing.md) {
                                field("Name", text: $name, content: .name)
                                Divider().overlay(Theme.hairline)
                                field("Phone", text: $phone, content: .telephoneNumber, keyboard: .phonePad)
                            }
                        }

                        Button("Save") {
                            services.supportContact.set(name: name, phone: phone)
                            BedrockHaptics.set()
                            dismiss()
                        }
                        .buttonStyle(.bedrockPrimary)
                        .disabled(!canSave)

                        if services.supportContact.hasContact {
                            Button("Remove current contact", role: .destructive) {
                                services.supportContact.clear()
                                dismiss()
                            }
                            .font(Theme.Typography.callout)
                        }
                    }
                    .padding(Theme.Spacing.xl)
                }
            }
            .navigationTitle("Your person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingPicker) {
                ContactPicker { pickedName, pickedPhone in
                    name = pickedName
                    phone = pickedPhone
                }
                .ignoresSafeArea()
            }
            .onAppear {
                if let existing = services.supportContact.contact {
                    name = existing.name
                    phone = existing.phone
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "phone.arrow.up.right.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.accent)
            Text("Who do you call when it's hard?")
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text("One tap to reach them in the moment. Their number stays on your phone — it's never uploaded.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private func field(_ label: String, text: Binding<String>, content: UITextContentType, keyboard: UIKeyboardType = .default) -> some View {
        HStack {
            Text(label)
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 64, alignment: .leading)
            TextField(label, text: text)
                .textContentType(content)
                .keyboardType(keyboard)
                .foregroundStyle(Theme.textPrimary)
        }
    }
}

/// Thin wrapper over `CNContactPickerViewController`. The picker is hosted by
/// the system, so the app sees only the single contact the user taps — no
/// Contacts authorization required.
private struct ContactPicker: UIViewControllerRepresentable {
    var onPick: (_ name: String, _ phone: String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: CNContactPickerViewController, context: Context) {}

    final class Coordinator: NSObject, CNContactPickerDelegate {
        let onPick: (_ name: String, _ phone: String) -> Void
        init(onPick: @escaping (_ name: String, _ phone: String) -> Void) { self.onPick = onPick }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let name = [contact.givenName, contact.familyName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            let phone = contact.phoneNumbers.first?.value.stringValue ?? ""
            onPick(name, phone)
        }
    }
}
