import CadenceCore
import SwiftUI

/// Atmospheric native settings view for configuring Cadence audio chimes, tactile haptics, and behaviors.
public struct SettingsView: View {
    @Bindable public var store: TimerStore

    public init(store: TimerStore) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SpacingScale.lg) {
                // Header
                HStack(spacing: SpacingScale.sm) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.cadenceAccent)

                    VStack(alignment: .leading, spacing: SpacingScale.xxs) {
                        Text("Preferences")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.cadenceTextPrimary)
                        Text("Atmospheric Focus & Tactile Utility")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.cadenceTextSecondary)
                    }
                    Spacer()
                }
                .padding(.bottom, SpacingScale.xs)

                // Section 1: Completion Audio
                CadenceCard {
                    VStack(alignment: .leading, spacing: SpacingScale.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: SpacingScale.xxs) {
                                Text("Audio Completion Chime")
                                    .font(.headline)
                                    .foregroundStyle(Color.cadenceTextPrimary)
                                Text("Play a soothing chime when a focus session concludes.")
                                    .font(.caption)
                                    .foregroundStyle(Color.cadenceTextSecondary)
                            }
                            Spacer()
                            Toggle(
                                "",
                                isOn: Binding(
                                    get: { store.isAudioAlertEnabled },
                                    set: { store.setAudioAlertEnabled($0) }
                                )
                            )
                            .toggleStyle(.switch)
                            .labelsHidden()
                        }

                        if store.isAudioAlertEnabled {
                            Divider()
                                .background(Color.cadenceBorder)

                            VStack(alignment: .leading, spacing: SpacingScale.xs) {
                                Text("Alert Sound")
                                    .font(.caption)
                                    .foregroundStyle(Color.cadenceTextSecondary)

                                ForEach(AudioAlertSound.allCases) { sound in
                                    HStack {
                                        Button {
                                            store.selectAudioSound(sound)
                                        } label: {
                                            HStack(spacing: SpacingScale.xs) {
                                                Image(
                                                    systemName: store.selectedAudioSound == sound
                                                        ? "circle.inset.filled" : "circle"
                                                )
                                                .foregroundStyle(
                                                    store.selectedAudioSound == sound
                                                        ? Color.cadenceAccent
                                                        : Color.cadenceTextSecondary)
                                                Text(sound.displayName)
                                                    .font(.body)
                                                    .foregroundStyle(Color.cadenceTextPrimary)
                                                Spacer()
                                            }
                                        }
                                        .buttonStyle(.plain)

                                        Button {
                                            store.previewSound(sound)
                                        } label: {
                                            Image(systemName: "speaker.wave.2.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(Color.cadenceAccent)
                                                .padding(6)
                                                .background(Color.cadenceBorder.opacity(0.5))
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(.plain)
                                        .help("Preview \(sound.displayName)")
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                }

                // Section 2: Tactile Feedback
                CadenceCard {
                    VStack(alignment: .leading, spacing: SpacingScale.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: SpacingScale.xxs) {
                                Text("Trackpad Haptic Feedback")
                                    .font(.headline)
                                    .foregroundStyle(Color.cadenceTextPrimary)
                                Text(
                                    "Subtle physical vibration on MacBook and Magic Trackpads upon start, pause, and completion."
                                )
                                .font(.caption)
                                .foregroundStyle(Color.cadenceTextSecondary)
                            }
                            Spacer()
                            Toggle(
                                "",
                                isOn: Binding(
                                    get: { store.isHapticsEnabled },
                                    set: { store.setHapticsEnabled($0) }
                                )
                            )
                            .toggleStyle(.switch)
                            .labelsHidden()
                        }
                    }
                }

                // Section 3: Window Behavior
                CadenceCard {
                    VStack(alignment: .leading, spacing: SpacingScale.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: SpacingScale.xxs) {
                                Text("Always-On-Top Window")
                                    .font(.headline)
                                    .foregroundStyle(Color.cadenceTextPrimary)
                                Text(
                                    "Keep the Cadence window floating above code editors and full-screen apps."
                                )
                                .font(.caption)
                                .foregroundStyle(Color.cadenceTextSecondary)
                            }
                            Spacer()
                            Toggle(
                                "",
                                isOn: Binding(
                                    get: { store.isAlwaysOnTop },
                                    set: { store.setAlwaysOnTop($0) }
                                )
                            )
                            .toggleStyle(.switch)
                            .labelsHidden()
                        }
                    }
                }

                // Section 4: Default Preset
                CadenceCard {
                    VStack(alignment: .leading, spacing: SpacingScale.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: SpacingScale.xxs) {
                                Text("Default Starting Preset")
                                    .font(.headline)
                                    .foregroundStyle(Color.cadenceTextPrimary)
                                Text("Preset selected when launching Cadence with a fresh session.")
                                    .font(.caption)
                                    .foregroundStyle(Color.cadenceTextSecondary)
                            }
                            Spacer()
                            Picker(
                                "",
                                selection: Binding(
                                    get: { store.selectedPreset },
                                    set: {
                                        if !store.phase.isRunning {
                                            store.selectPreset($0)
                                        }
                                    }
                                )
                            ) {
                                ForEach(TimerPreset.allCases) { preset in
                                    if preset != .custom {
                                        Text(preset.displayName).tag(preset)
                                    }
                                }
                            }
                            .disabled(store.phase.isRunning)
                            .frame(width: 140)
                        }
                    }
                }

                // Footer
                HStack {
                    Text("Cadence v0.3.0 • Pure Native Focus Utility")
                        .font(.caption2)
                        .foregroundStyle(Color.cadenceTextSecondary.opacity(0.7))
                    Spacer()
                }
                .padding(.top, SpacingScale.xs)
            }
            .padding(SpacingScale.lg)
        }
        .background(Color.cadenceBackground)
        .frame(minWidth: 440, idealWidth: 460, minHeight: 460, idealHeight: 520)
    }
}
