import SwiftUI

struct OnboardingView: View {
    @Bindable var settings: AppSettings
    @State private var currentStep = 0
    
    var body: some View {
        VStack {
            TabView(selection: $currentStep) {
                WelcomeStep(currentStep: $currentStep)
                    .tag(0)
                
                CalibrationStep(settings: settings, currentStep: $currentStep)
                    .tag(1)
                
                GoalStep(settings: settings, currentStep: $currentStep)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Welcome Step

struct WelcomeStep: View {
    @Binding var currentStep: Int
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "flame.fill")
                .font(.system(size: 80))
                .foregroundStyle(.orange.gradient)
            
            Text("Welcome to Cordkeeper")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Track your firewood consumption\nthroughout the heating season")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            VStack(spacing: 16) {
                FeatureRow(icon: "plus.circle.fill", title: "Log quickly", subtitle: "Add logs with a single tap")
                FeatureRow(icon: "chart.bar.fill", title: "Track usage", subtitle: "See your cord consumption")
                FeatureRow(icon: "clock.fill", title: "Review history", subtitle: "Browse past fires")
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: { currentStep = 1 }) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.orange.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.orange)
                .frame(width: 44)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Calibration Step

struct CalibrationStep: View {
    @Bindable var settings: AppSettings
    @Binding var currentStep: Int
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "ruler.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange.gradient)
            
            Text("Calibrate Your Wood")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("How many medium-sized splits\nmake up one cord of your wood?")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            VStack(spacing: 20) {
                HStack {
                    Text("\(Int(settings.unitsPerCord))")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                    Text("pieces")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: $settings.unitsPerCord, in: 100...800, step: 10)
                    .tint(.orange)
                    .padding(.horizontal)
                
                Text("Most people use 300-500 depending on split size")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: { currentStep = 0 }) {
                    Text("Back")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                Button(action: { currentStep = 2 }) {
                    Text("Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Goal Step

struct GoalStep: View {
    @Bindable var settings: AppSettings
    @Binding var currentStep: Int
    @State private var hasGoal = true
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundStyle(.orange.gradient)
            
            Text("Set a Season Goal")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("How many cords do you expect\nto burn this season?")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            VStack(spacing: 20) {
                Toggle("Track against a goal", isOn: $hasGoal)
                    .tint(.orange)
                
                if hasGoal {
                    HStack {
                        Text(String(format: "%.1f", settings.seasonGoal ?? 3.0))
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundStyle(.orange)
                        Text("cords")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { settings.seasonGoal ?? 3.0 },
                            set: { settings.seasonGoal = $0 }
                        ),
                        in: 0.5...10,
                        step: 0.5
                    )
                    .tint(.orange)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: { currentStep = 1 }) {
                    Text("Back")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                Button(action: completeOnboarding) {
                    Text("Start Tracking")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    private func completeOnboarding() {
        if !hasGoal {
            settings.seasonGoal = nil
        }
        settings.hasCompletedOnboarding = true
    }
}

#Preview {
    OnboardingView(settings: AppSettings())
}
