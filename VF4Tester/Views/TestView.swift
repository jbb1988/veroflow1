import SwiftUI
import Foundation
#if os(iOS)
import UIKit
#endif
import AVFoundation

// Reusable Test Type Button remains unchanged.
struct TestTypeButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let borderColor: Color
    let action: () -> Void
        @State private var feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
        // Neumorphic effect properties
    private let darkShadow = Color.black.opacity(0.2)
    private let lightShadow = Color.white.opacity(0.7)
    
    private var neumorphicBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(isSelected ? borderColor.opacity(0.8) : Color.blue.opacity(0.3))
            if isSelected {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(borderColor, lineWidth: 2)
            }
            RoundedRectangle(cornerRadius: 20)
                .stroke(darkShadow, lineWidth: 4)
                .blur(radius: 4)
                .offset(x: 2, y: 2)
                .mask(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(gradient: Gradient(colors: [.black, .clear]),
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                )
            RoundedRectangle(cornerRadius: 20)
                .stroke(lightShadow, lineWidth: 4)
                .blur(radius: 4)
                .offset(x: -2, y: -2)
                .mask(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(gradient: Gradient(colors: [.clear, .black]),
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                )
        }
    }
    
    var body: some View {
        Button(action: {
                    feedbackGenerator.prepare()
                    feedbackGenerator.impactOccurred()
                    action()
                }) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .foregroundColor(.white)
            .background(neumorphicBackground)
        }
        .buttonStyle(PlainButtonStyle())
    }
}



func sanitizeNumericInput(_ input: String) -> String {
    input
        .replacingOccurrences(of: "'", with: ".")
        .replacingOccurrences(of: "`", with: "")
        .replacingOccurrences(of: "٫", with: ".")
        .replacingOccurrences(of: "،", with: ".")
}

private struct DotPattern: View {
    var body: some View {
        GeometryReader { geometry in
            ForEach(0...Int(geometry.size.width/15), id: \.self) { x in
                ForEach(0...Int(geometry.size.height/15), id: \.self) { y in
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 2, height: 2)
                        .position(x: CGFloat(x) * 15 + 7.5,
                                  y: CGFloat(y) * 15 + 7.5)
                }
            }
        }
    }
}

private struct GradientBackground: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "004F89"),
                        Color(hex: "002A4A")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            DotPattern()
        }
    }
}

private struct ParameterTextField: View {
    let text: Binding<String>
    let field: Field
    let showValidation: Bool
    let onChangeHandler: (String) -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextField("", text: text)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.leading)
            .frame(width: 100, height: 15)
            .textFieldStyle(PlainTextFieldStyle())
            .padding(8)
            .background(Color.black)
            .overlay(RoundedRectangle(cornerRadius: 8)
                .stroke(showValidation && text.wrappedValue.isEmpty ? Color.red : Color.blue.opacity(0.9), lineWidth: 2))
        // ADD: Neon glow effect
                    .shadow(color: Color.blue.opacity(0.5), radius: 4, x: 0, y: 0)
                    .focused($isFocused)
                    .onChange(of: text.wrappedValue) { onChangeHandler($0) }

    }
}

private struct ParameterRow: View {
    let title: String
    let icon: String
    let text: Binding<String>
    let field: Field
    let showValidation: Bool
    let unit: String
    let onChangeHandler: (String) -> Void
    let primaryColor: Color
    
    var body: some View {
        HStack(spacing: 0) {
            Label(title, systemImage: icon)
                .foregroundColor(primaryColor)
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)
            Spacer()
            HStack(spacing: 8) {
                ParameterTextField(
                    text: text,
                    field: field,
                    showValidation: showValidation,
                    onChangeHandler: onChangeHandler
                )
                Text(unit)
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .leading)
            }
        }
    }
}

private struct TotalVolumeParameterView: View {
    let totalVolumeText: Binding<String>
    let field: Field
    let showValidation: Bool
    let unit: String
    let viewModel: TestViewModel
    let primaryColor: Color
    
    var body: some View {
        ParameterRow(
            title: "Total Volume",
            icon: "drop",
            text: totalVolumeText,
            field: field,
            showValidation: showValidation,
            unit: unit,
            onChangeHandler: { newValue in
                if let value = Double(sanitizeNumericInput(newValue)) {
                    viewModel.totalVolume = value
                }
            },
            primaryColor: primaryColor
        )
    }
}

private struct FlowRateParameterView: View {
    let flowRateText: Binding<String>
    let field: Field
    let showValidation: Bool
    let viewModel: TestViewModel
    let primaryColor: Color
    
    var body: some View {
        ParameterRow(
            title: "Flow Rate",
            icon: "water.waves",
            text: flowRateText,
            field: field,
            showValidation: showValidation,
            unit: "GPM",
            onChangeHandler: { newValue in
                if let value = Double(sanitizeNumericInput(newValue)) {
                    viewModel.flowRate = value
                }
            },
            primaryColor: primaryColor
        )
    }
}

struct TestView: View {
    @EnvironmentObject var viewModel: TestViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var isLandscape: Bool {
        horizontalSizeClass == .regular
    }
    @FocusState private var focusedField: Field?
    @State private var keyboardHeight: CGFloat = 0
    @State private var isNotesFieldFocused: Bool = false
    @State private var showingClearConfirmation = false
    @State private var showToast = false
    @State private var isRecordSuccess = false
    @State private var showingValidationAlert = false
    @State private var validationErrors: [String] = []

    @AppStorage("showMeterMfgInput") var showMeterMfgInput: Bool = true
    @AppStorage("showMeterModelInput") var showMeterModelInput: Bool = true

    private let headerSpacing: CGFloat = 60

    // Input State Variables
    @State private var totalVolumeText: String = ""
    @State private var flowRateText: String = ""
    @State private var selectedMeterSize: MeterSize = .two
    @State private var selectedMeterType: MeterType = {
        if let defaultMfg = UserDefaults.standard.string(forKey: "defaultMeterManufacturer"),
           let meterType = MeterType(rawValue: defaultMfg) {
            return meterType
        }
        return .other
    }()
    @State private var selectedMeterModel: MeterModel = .positiveDisplacement
    @State private var jobNumberText: String = ""
    @State private var additionalRemarksText: String = ""
    @State private var isCompoundMeter: Bool = false

    enum SingleMeterOption: String, CaseIterable {
        case small = "Small Meter"
        case large = "Large Meter"
    }
    @State private var selectedSingleMeter: SingleMeterOption = .small
    @State private var selectedCompoundSmallMeterSize: MeterSize = .one
    @State private var selectedCompoundLargeMeterSize: MeterSize = .one

    // Custom colors
    private let primaryColor = Color.blue
    private let accentColor = Color.purple
    private let successColor = Color.green

    private let darkShadow = Color.black.opacity(0.2)
    private let lightShadow = Color.white.opacity(0.7)

    private var sectionHeaderColor: Color {
        colorScheme == .dark ? .white : .black
    }

    // Computed property for pass range display
    var passRangeText: String {
        let model = selectedMeterModel
        let test = viewModel.currentTest
        let (minTol, maxTol): (Double, Double) = {
            switch model {
            case .positiveDisplacement, .singleJet:
                switch test {
                case .lowFlow: return (95.0, 101.5)
                case .midFlow, .highFlow: return (98.5, 101.5)
                }
            case .multiJet:
                switch test {
                case .lowFlow: return (97.0, 103.0)
                case .midFlow, .highFlow: return (98.5, 101.5)
                }
            case .turbine: return (98.5, 101.5)
            case .typeI, .typeII, .electromagnetic, .ultrasonic:
                switch test {
                case .lowFlow: return (95.0, 105.0)
                case .midFlow, .highFlow: return (98.5, 101.5)
                }
            case .fireservice:
                switch test {
                case .lowFlow: return (95.0, 101.5)
                case .midFlow, .highFlow: return (98.5, 101.5)
                }
            case .compound:
                switch test {
                case .lowFlow: return (95.0, 101.0)
                case .midFlow: return (98.5, 101.5)
                case .highFlow: return (97.0, 103.0)
                }
            case .other:
                switch test {
                case .lowFlow: return (95.0, 101.0)
                case .midFlow: return (97.0, 101.5)
                case .highFlow: return (98.5, 101.5)
                }
            }
        }()
        return String(format: "%.1f%% - %.1f%%", minTol, maxTol)
    }

    private func testTypeBorderColor(for test: TestType) -> Color {
        switch test {
        case .lowFlow: return .blue
        case .midFlow: return .orange
        case .highFlow: return .pink
        }
    }

    private func validateFields() -> Bool {
        var isValid = true
        validationErrors.removeAll()
        
        if viewModel.smallMeterStart.isEmpty {
            isValid = false
            validationErrors.append("Start Read")
        }
        if viewModel.smallMeterEnd.isEmpty {
            isValid = false
            validationErrors.append("End Read")
        }
        if totalVolumeText.isEmpty {
            isValid = false
            validationErrors.append("Total Volume")
        }
        if flowRateText.isEmpty {
            isValid = false
            validationErrors.append("Flow Rate")
        }
        if !isValid {
            withAnimation {
                showValidationOutlines = true
                showingValidationAlert = true
            }
        }
        return isValid
    }
    
    private let gradientColor1 = Color(red: 0/255, green: 126/255, blue: 189/255)
    private let gradientColor2 = Color(red: 20/255, green: 61/255, blue: 110/255)
    
    // MARK: - UI Sections
    
    private var testTypeSection: some View {
        DetailCard(title: "Test Type") {
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    TestTypeButton(title: "Low Flow",
                                   subtitle: "(0.75-35 GPM)",
                                   isSelected: viewModel.currentTest == .lowFlow,
                                   borderColor: testTypeBorderColor(for: .lowFlow)) {
                        viewModel.currentTest = .lowFlow
                    }
                    TestTypeButton(title: "Mid Flow",
                                   subtitle: "(15-100 GPM)",
                                   isSelected: viewModel.currentTest == .midFlow,
                                   borderColor: testTypeBorderColor(for: .midFlow)) {
                        viewModel.currentTest = .midFlow
                    }
                    TestTypeButton(title: "High Flow",
                                   subtitle: "(25-650 GPM)",
                                   isSelected: viewModel.currentTest == .highFlow,
                                   borderColor: testTypeBorderColor(for: .highFlow)) {
                        viewModel.currentTest = .highFlow
                    }
                }
            }
        }
    }
    
    private var meterReadingsSection: some View {
        DetailCard(title: "Meter Readings") {
            Toggle("Compound Meter", isOn: $isCompoundMeter)
                .padding(.vertical, 4)
            if isCompoundMeter {
                smallMeterReadings
                Divider()
                largeMeterReadings
            } else {
                HStack(spacing: 8) {
                    Button(action: {
                        let feedback = UIImpactFeedbackGenerator(style: .medium)
                        feedback.prepare()
                        feedback.impactOccurred()
                        selectedSingleMeter = .small
                    }) {
                        VStack(spacing: 4) {
                            Text("Small Meter")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            ZStack {
                                LinearGradient(gradient: Gradient(colors: [Color(hex: "001830").opacity(0.7), Color(hex: "000C18").opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                                VisualEffectBlur(blurStyle: .systemUltraThinMaterial)
                                if selectedSingleMeter == .small {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 150, height: 150)
                                        .blur(radius: 60)
                                        .offset(y: -30)
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.blue.opacity(selectedSingleMeter == .small ? 0.8 : 0.4), lineWidth: 2)
                        )
                        .shadow(color: Color.blue.opacity(selectedSingleMeter == .small ? 0.5 : 0.2), radius: 20, x: 0, y: 10)
                    }

                    Button(action: {
                        let feedback = UIImpactFeedbackGenerator(style: .medium)
                        feedback.prepare()
                        feedback.impactOccurred()
                        selectedSingleMeter = .large
                    }) {
                        VStack(spacing: 4) {
                            Text("Large Meter")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 41)
                        .background(
                            ZStack {
                                LinearGradient(gradient: Gradient(colors: [Color(hex: "001830").opacity(0.7), Color(hex: "000C18").opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                                VisualEffectBlur(blurStyle: .systemUltraThinMaterial)
                                if selectedSingleMeter == .large {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 150, height: 150)
                                        .blur(radius: 60)
                                        .offset(y: -30)
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.blue.opacity(selectedSingleMeter == .large ? 0.8 : 0.4), lineWidth: 2)
                        )
                        .shadow(color: Color.blue.opacity(selectedSingleMeter == .large ? 0.5 : 0.2), radius: 20, x: 0, y: 10)
                    }
                }
                .padding(.vertical, 4)
                
                if selectedSingleMeter == .small {
                    smallMeterReadings
                } else {
                    largeMeterReadings
                }
            }
        }
    }
    
    private var smallMeterReadings: some View {
        VStack(alignment: .leading) {
            Label("Small Meter Reading", systemImage: "speedometer")
                .font(.subheadline)
                .bold()
                .foregroundColor(primaryColor)
            HStack {
                MarsReadingField(title: "Start Read", text: $viewModel.smallMeterStart, field: .smallStart)
                Spacer()
                MarsReadingField(title: "End Read", text: $viewModel.smallMeterEnd, field: .smallEnd)
            }
            HStack(spacing: 12) {
                Button(action: {
                                    let feedback = UIImpactFeedbackGenerator(style: .medium)
                                    feedback.prepare()
                                    feedback.impactOccurred()
                                    selectedImageSource = .camera
}) {
                    HStack {
                        Image(systemName: "camera")
                        Text("Capture Meter")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: 175)
                    .frame(height: 40.8)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(primaryColor.opacity(0.7))
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(darkShadow, lineWidth: 4)
                                .blur(radius: 4)
                                .offset(x: 2, y: 2)
                                .mask(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(LinearGradient(gradient: Gradient(colors: [.black, .clear]),
                                                             startPoint: .topLeading,
                                                             endPoint: .bottomTrailing))
                                )
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(lightShadow, lineWidth: 4)
                                .blur(radius: 4)
                                .offset(x: -2, y: -2)
                                .mask(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(LinearGradient(gradient: Gradient(colors: [.clear, .black]),
                                                             startPoint: .topLeading,
                                                             endPoint: .bottomTrailing))
                                )
                        }
                    )
                }
                Spacer()
                VStack {
                    meterImageIndicator
                    if hasStoredImage { capturedImagePreview }
                }
            }
            .padding(.top, 8)
        }
    }
    
    private var largeMeterReadings: some View {
        VStack(alignment: .leading) {
            Label("Large Meter Reading", systemImage: "dial.max")
                .font(.subheadline)
                .bold()
                .foregroundColor(primaryColor)
            HStack {
                MarsReadingField(title: "Start Read", text: $viewModel.largeMeterStart, field: .largeStart)
                Spacer()
                MarsReadingField(title: "End Read", text: $viewModel.largeMeterEnd, field: .largeEnd)
            }
            HStack(spacing: 12) {
                Button(action: {
                    let feedback = UIImpactFeedbackGenerator(style: .medium)
                    feedback.prepare()
                    feedback.impactOccurred()
                    selectedImageSource = .camera
                }) {
                    HStack {
                        Image(systemName: "camera")
                        Text("Capture Meter")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: 175)
                    .frame(height: 48)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(primaryColor.opacity(0.7))
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(darkShadow, lineWidth: 4)
                                .blur(radius: 4)
                                .offset(x: 2, y: 2)
                                .mask(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(LinearGradient(gradient: Gradient(colors: [.black, .clear]),
                                                             startPoint: .topLeading,
                                                             endPoint: .bottomTrailing))
                                )
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(lightShadow, lineWidth: 4)
                                .blur(radius: 4)
                                .offset(x: -2, y: -2)
                                .mask(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(LinearGradient(gradient: Gradient(colors: [.clear, .black]),
                                                             startPoint: .topLeading,
                                                             endPoint: .bottomTrailing))
                                )
                        }
                    )
                }
                Spacer()
                VStack {
                    meterImageIndicator
                    if hasStoredImage { capturedImagePreview }
                }
            }
            .padding(.top, 8)
        }
    }
    
     

    private var testParametersSection: some View {
        DetailCard(title: "Test Parameters") {
            VStack(spacing: 12) {
                TotalVolumeParameterView(
                    totalVolumeText: $totalVolumeText,
                    field: .totalVolume,
                    showValidation: showValidationOutlines,
                    unit: viewModel.configuration.preferredVolumeUnit.rawValue,
                    viewModel: viewModel,
                    primaryColor: primaryColor
                )
                
                FlowRateParameterView(
                    flowRateText: $flowRateText,
                    field: .flowRate,
                    showValidation: showValidationOutlines,
                    viewModel: viewModel,
                    primaryColor: primaryColor
                )
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var meterDetailsSection: some View {
        DetailCard(title: "Meter Details") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Meter Size", systemImage: "ruler")
                        .foregroundColor(primaryColor)
                    if isCompoundMeter {
                        VStack {
                            Picker("Small Meter", selection: $selectedCompoundSmallMeterSize) {
                                ForEach(MeterSize.allCases, id: \.self) { size in
                                    Text(size.rawValue).tag(size)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            Picker("Large Meter", selection: $selectedCompoundLargeMeterSize) {
                                ForEach(MeterSize.allCases, id: \.self) { size in
                                    Text(size.rawValue).tag(size)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    } else {
                        Picker("", selection: $selectedMeterSize) {
                            ForEach(MeterSize.allCases, id: \.self) { size in
                                Text(size.rawValue).tag(size)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                if showMeterMfgInput {
                    HStack {
                        Label("Meter Mfg.", systemImage: "dial.medium")
                            .foregroundColor(primaryColor)
                        Picker("", selection: $selectedMeterType) {
                            ForEach(MeterType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .onChange(of: viewModel.configuration.defaultMeterManufacturer) { newValue in
                            if let meterType = MeterType(rawValue: newValue) {
                                selectedMeterType = meterType
                            }
                        }
                    }
                }
                if showMeterModelInput {
                    HStack {
                        Label("Meter Type", systemImage: "gear")
                            .foregroundColor(primaryColor)
                        Picker("", selection: $selectedMeterModel) {
                            ForEach(MeterModel.allCases, id: \.self) { model in
                                Text(model.rawValue).tag(model)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
        }
    }
    
    private var additionalDetailsSection: some View {
        DetailCard(title: "Additional Details") {
            HStack {
                Label("Serial Number", systemImage: "number")
                    .foregroundColor(primaryColor)
                TextField("Optional", text: $jobNumberText)
                    .frame(height: 15)
                    .padding(8)
                    .background(Color.black)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.9), lineWidth: 2)
                    )
                    .shadow(color: Color.blue.opacity(0.5), radius: 4, x: 0, y: 0)
                    .focused($focusedField, equals: .jobNumber)
            }
        }
    }
    
    private var notesSection: some View {
        DetailCard(title: "Notes") {
            TextEditor(text: $viewModel.notes)
                .frame(minHeight: 200)
                .placeholder(when: viewModel.notes.isEmpty, placeholder: "Enter additional notes here...")
                .padding(8)
                .background(Color.black)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.9), lineWidth: 2)
                )
                .shadow(color: Color.blue.opacity(0.5), radius: 4, x: 0, y: 0)
                .focused($focusedField, equals: .additionalRemarks)
        }
        .id("notesSection")
    }
    
    // MARK: - Animated Record Test Button Section
    @State private var rotation: CGFloat = 0
    @State private var showingTestDetail = false
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var capturedImageData: Data? = nil
    @State private var hasStoredImage = false
    @State private var showOCRActionSheet = false
    
    @State private var recognizedText: String? = nil
    @State private var showValidationOutlines = false
    @State private var rawInputs: [String: String] = [:]
    @State private var isProcessingImage = false
    @State private var showDetectionSuccess = false
    @State private var detectedReadingValue: String? = nil
    
    private var recordTestSection: some View {
        DetailCard(title: "Record Test") {
            HStack(spacing: 16) {
        Button(action: {
                    let feedback = UIImpactFeedbackGenerator(style: .medium)
                    feedback.prepare()
                    feedback.impactOccurred()
                    recordTest()
                }) {
                    Text(isRecordSuccess ? "Test Recorded!" : "Record Test")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            ZStack {
                                LinearGradient(gradient: Gradient(colors: [Color(hex: "003366"), Color(hex: "007AFF")]),
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
                                VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                                if isRecordSuccess {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.blue)
                                        .blur(radius: 20)
                                        .opacity(0.3)
                                        .scaleEffect(1.2)
                                        .animation(.easeInOut(duration: 1.0), value: isRecordSuccess)
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.blue.opacity(0.9), lineWidth: 2)
                        )
                        .shadow(color: Color.blue.opacity(0.5), radius: 20, x: 0, y: 10)
                }
        Button(action: {
                    let feedback = UIImpactFeedbackGenerator(style: .medium)
                    feedback.prepare()
                    feedback.impactOccurred()
                    showingClearConfirmation = true
                }) {
                    Text("Clear Inputs")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            ZStack {
                                LinearGradient(gradient: Gradient(colors: [Color(hex: "660000"), Color(hex: "FF2D55")]),
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
                                VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.red.opacity(0.9), lineWidth: 2)
                        )
                        .shadow(color: Color.red.opacity(0.5), radius: 20, x: 0, y: 10)
                }
            }
            .alert("Missing Required Fields", isPresented: $showingValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please fill in the following fields:\n" + validationErrors.joined(separator: "\n"))
            }
            .alert(isPresented: $showingClearConfirmation) {
                Alert(title: Text("Clear All Inputs"),
                      message: Text("Are you sure you want to clear all test inputs?"),
                      primaryButton: .destructive(Text("Clear")) { clearAllFields() },
                      secondaryButton: .cancel())
            }
        }
    }
    
    private var recentTestSection: some View {
        Group {
            if viewModel.isCalculatingResults {
                DetailCard(title: "Recent Test") {
                    ProgressView("Calculating...")
                        .progressViewStyle(CircularProgressViewStyle())
                }
            } else if let lastResult = viewModel.lastTestResult {
                DetailCard(title: "Recent Test") {
                    Button {
                        showingTestDetail = true
                    } label: {
                        latestResultSection(result: lastResult)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .sheet(isPresented: $showingTestDetail) {
                    TestDetailView(result: lastResult)
                }
            }
        }
    }
    
    @State private var isAnimating = false
    private func startAnimation() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            isAnimating.toggle()
        }
    }
    
    private func passRangeForResult(_ result: TestResult) -> String {
        let test = result.testType
        if let model = MeterModel(rawValue: result.meterModel) {
            let (minTol, maxTol): (Double, Double) = {
                switch model {
                case .positiveDisplacement, .singleJet:
                    switch test {
                    case .lowFlow: return (95.0, 101.5)
                    case .midFlow, .highFlow: return (98.5, 101.5)
                    }
                case .multiJet:
                    switch test {
                    case .lowFlow: return (97.0, 103.0)
                    case .midFlow, .highFlow: return (98.5, 101.5)
                    }
                case .turbine: return (98.5, 101.5)
                case .typeI, .typeII, .electromagnetic, .ultrasonic:
                    switch test {
                    case .lowFlow: return (95.0, 105.0)
                    case .midFlow, .highFlow: return (98.5, 101.5)
                    }
                case .fireservice:
                    switch test {
                    case .lowFlow: return (95.0, 101.5)
                    case .midFlow, .highFlow: return (98.5, 101.5)
                    }
                case .compound:
                    switch test {
                    case .lowFlow: return (95.0, 101.0)
                    case .midFlow: return (98.5, 101.5)
                    case .highFlow: return (97.0, 103.0)
                    }
                case .other:
                    switch test {
                    case .lowFlow: return (95.0, 101.0)
                    case .midFlow: return (97.0, 101.5)
                    case .highFlow: return (98.5, 101.5)
                    }
                }
            }()
            return String(format: "%.1f%% - %.1f%%", minTol, maxTol)
        } else {
            switch test {
            case .lowFlow: return "95.0% - 101.0%"
            case .midFlow: return "97.0% - 101.5%"
            case .highFlow: return "98.5% - 101.5%"
            }
        }
    }
    
    private func latestResultSection(result: TestResult) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(result.isPassing ? Color.green : Color.red)
                .frame(width: 8, height: 8)
                .padding(4)
                .background(Circle().fill(result.isPassing ? Color.green.opacity(0.2) : Color.red.opacity(0.2)))
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(result.testType.rawValue)
                        .font(.headline)
                    Spacer()
                    Text(String(format: "%.1f%%", result.reading.accuracy))
                        .font(.title3)
                        .bold()
                        .foregroundColor(result.isPassing ? .green : .red)
                }
                Text(result.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack(spacing: 12) {
                    Label(String(format: "%.1f", result.reading.smallMeterStart),
                          systemImage: "arrow.forward.circle.fill")
                        .foregroundColor(.blue)
                    Label(String(format: "%.1f", result.reading.smallMeterEnd),
                          systemImage: "arrow.backward.circle.fill")
                        .foregroundColor(.purple)
                    Label(String(format: "%.1f Gal", result.reading.totalVolume),
                          systemImage: "drop.fill")
                        .foregroundColor(.cyan)
                }
                .font(.footnote)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        // ADD: Neon blue border and glow effect
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.9), lineWidth: 2)
        )
        .shadow(color: Color.blue.opacity(0.5), radius: 4, x: 0, y: 0)
        .contentShape(Rectangle())
    }
    
 
    
    private func clearAllFields() {
        totalVolumeText = ""
        flowRateText = ""
        jobNumberText = ""
        additionalRemarksText = ""
        viewModel.smallMeterStart = ""
        viewModel.smallMeterEnd = ""
        viewModel.largeMeterStart = ""
        viewModel.largeMeterEnd = ""
        viewModel.totalVolume = 0
        viewModel.flowRate = 0
        viewModel.notes = ""
        selectedMeterSize = .one
        selectedMeterType = {
            if let defaultMfg = UserDefaults.standard.string(forKey: "defaultMeterManufacturer"),
               let meterType = MeterType(rawValue: defaultMfg) {
                return meterType
            }
            return .neptune
        }()
        selectedMeterModel = .positiveDisplacement
        dismissKeyboard()
        showValidationOutlines = false
        capturedImage = nil
        capturedImageData = nil
        hasStoredImage = false
    }
    
    private func recordTest() {
        LocationManager.shared.fetchCurrentLocation()
        dismissKeyboard()
        showValidationOutlines = true
        if !validateFields() { return }
        
        print("Recording test with raw inputs:")
        rawInputs.forEach { key, value in print("\(key): \(value)") }
        
        viewModel.isCalculatingResults = true
        withAnimation(.spring(response: 0.3)) { isRecordSuccess = true }
        
        let meterSizeValue = isCompoundMeter
            ? "\(selectedCompoundSmallMeterSize.rawValue)/\(selectedCompoundLargeMeterSize.rawValue)"
            : selectedMeterSize.rawValue
        
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1) {
            let fixedLatitude = self.viewModel.latitude
            let fixedLongitude = self.viewModel.longitude
            self.viewModel.calculateResults(
                with: self.capturedImageData != nil ? [self.capturedImageData!] : [],
                meterSize: meterSizeValue,
                meterType: self.selectedMeterType.rawValue,
                meterModel: self.selectedMeterModel.rawValue,
                jobNumber: self.jobNumberText,
                readingType: self.isCompoundMeter ? .compound : (self.selectedSingleMeter == .small ? .small : .large),
                latitude: fixedLatitude,
                longitude: fixedLongitude
            )
            self.showToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.clearAllFields()
                self.viewModel.isCalculatingResults = false
                withAnimation { self.isRecordSuccess = false }
            }
        }
    }
    
    private func dismissKeyboard() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
    
    // Simplified OCR implementation focused on accurate meter reading detection
    private func performBasicOCR(for image: UIImage, completion: @escaping (Bool) -> Void) {
        print("Starting water meter OCR process...")
        OCRManager.shared.recognizeText(in: image) { text in
            var success = false
            if let text = text {
                print("OCR Raw Text: \(text)")
                let normalizedText = text.lowercased().replacingOccurrences(of: " ", with: "")
                for type in MeterType.allCases {
                    let normalizedType = type.rawValue.lowercased().replacingOccurrences(of: " ", with: "")
                    if normalizedText.contains(normalizedType) {
                        self.selectedMeterType = type
                        print("Auto-selected Meter Manufacturer: \(type.rawValue)")
                        break
                    }
                }
                for type in MeterType.allCases {
                    if text.localizedCaseInsensitiveContains(type.rawValue) {
                        self.selectedMeterType = type
                        print("Auto-selected Meter Manufacturer: \(type.rawValue)")
                        break
                    }
                }
                for size in MeterSize.allCases {
                    let normalizedSize = size.rawValue.lowercased().replacingOccurrences(of: " ", with: "")
                    if normalizedText.contains(normalizedSize) {
                        self.selectedMeterSize = size
                        print("Auto-selected Meter Size: \(size.rawValue)")
                        break
                    }
                }
                
                var bestMeterReading: String? = nil
                let nsString = text as NSString
                let decimalPattern = "\\b\\d+\\.\\d+\\b"
                if let regex = try? NSRegularExpression(pattern: decimalPattern, options: []) {
                    let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
                    for match in matches {
                        let matchString = nsString.substring(with: match.range)
                        let surroundRange = NSRange(location: max(0, match.range.location - 1),
                                                    length: min(nsString.length - match.range.location + 1, match.range.length + 2))
                        let surroundText = nsString.substring(with: surroundRange)
                        let hasSpecialChar = surroundText.rangeOfCharacter(from: CharacterSet(charactersIn: "#@$%^&*+=<>{}[]|\\:;")) != nil
                        if !hasSpecialChar, let value = Double(matchString), value > 0 {
                            bestMeterReading = matchString
                            print("Found meter reading with decimal: \(matchString)")
                            break
                        }
                    }
                }
                if bestMeterReading == nil {
                    let gallonsPattern = "(\\d+(?:,\\d{3})*(?:\\.\\d+)?)(?=\\s*(?:gal(?:lon)?s?))"
                    if let regex = try? NSRegularExpression(pattern: gallonsPattern, options: .caseInsensitive) {
                        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
                        if let match = matches.first {
                            let matchString = nsString.substring(with: match.range)
                            bestMeterReading = matchString.replacingOccurrences(of: ",", with: "")
                            print("Found numeric preceding 'gal/gallon/gallons': \(matchString) normalized to \(bestMeterReading!)")
                        }
                    }
                }
                if bestMeterReading == nil {
                    let digitPattern = "\\b\\d{5,8}\\b"
                    if let regex = try? NSRegularExpression(pattern: digitPattern, options: []) {
                        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
                        for match in matches {
                            let matchString = nsString.substring(with: match.range)
                            let surroundRange = NSRange(location: max(0, match.range.location - 1),
                                                        length: min(nsString.length - match.range.location + 1, match.range.length + 2))
                            let surroundText = nsString.substring(with: surroundRange)
                            let hasSpecialChar = surroundText.rangeOfCharacter(from: CharacterSet(charactersIn: "#@$%^&*+=<>{}[]|\\:;")) != nil
                            if !hasSpecialChar, let value = Double(matchString), value > 0 {
                                bestMeterReading = matchString
                                print("Found digit sequence as meter reading: \(matchString)")
                                break
                            }
                        }
                    }
                }
                if bestMeterReading == nil {
                    let potentialDecimalPattern = "\\b(\\d+)\\s+(\\d{1,3})\\b"
                    if let regex = try? NSRegularExpression(pattern: potentialDecimalPattern, options: []) {
                        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
                        for match in matches {
                            if match.numberOfRanges >= 3 {
                                let wholePart = nsString.substring(with: match.range(at: 1))
                                let decimalPart = nsString.substring(with: match.range(at: 2))
                                if decimalPart.count <= 3 {
                                    let combined = "\(wholePart).\(decimalPart)"
                                    bestMeterReading = combined
                                    print("Reconstructed decimal reading: \(combined)")
                                    break
                                }
                            }
                        }
                    }
                }
                
                // Extract serial number using the helper method.
                if let serial = self.extractSerialNumber(from: text) {
                    self.jobNumberText = serial
                    print("Extracted serial number: \(serial)")
                }
                
                DispatchQueue.main.async {
                    var detectedInfo: [String] = []
                    if let reading = bestMeterReading {
                        if self.selectedSingleMeter == .small {
                            self.viewModel.smallMeterStart = reading
                        } else {
                            self.viewModel.largeMeterStart = reading
                        }
                        success = true
                        self.detectedReadingValue = reading
                        detectedInfo.append("Meter reading: \(reading)")
                    }
                    detectedInfo.append("\nDetected Text:")
                    let allTextLines = text.components(separatedBy: .newlines)
                    let significantLines = allTextLines.filter { line in
                        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        return !trimmed.isEmpty && trimmed.count >= 3
                    }
                    for line in significantLines {
                        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty { detectedInfo.append(trimmed) }
                    }
                    let existingNotes = self.viewModel.notes
                    let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
                    let newInfo = "--- Auto-Detected Information (\(timestamp)) ---\n" + detectedInfo.joined(separator: "\n")
                    if existingNotes.isEmpty {
                        self.viewModel.notes = newInfo
                    } else {
                        self.viewModel.notes = existingNotes + "\n\n" + newInfo
                    }
                    withAnimation {
                        self.isProcessingImage = false
                        self.showDetectionSuccess = success
                    }
                    if success {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { self.showDetectionSuccess = false }
                        }
                    } else {
                        self.recognizedText = text
                        self.showOCRActionSheet = true
                    }
                    completion(success)
                }
            } else {
                DispatchQueue.main.async {
                    withAnimation { self.isProcessingImage = false }
                    completion(false)
                }
            }
        }
    }
    
    @State private var showImageSourceSheet = false
    @State private var selectedImageSource: PickerSource?
    
    private var meterImageIndicator: some View {
        HStack {
            if isProcessingImage {
                ProgressView()
                    .scaleEffect(0.8)
                    .padding(.trailing, 2)
                Text("Analyzing meter...")
                    .foregroundColor(.orange)
            } else if showDetectionSuccess {
                Image(systemName: "number.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 16, weight: .bold))
                    .scaleEffect(showDetectionSuccess ? 1.2 : 1.0)
                    .animation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: showDetectionSuccess)
                if let detectedValue = detectedReadingValue {
                    Text("Reading \(detectedValue) detected!")
                        .foregroundColor(.green)
                        .font(.system(size: 14, weight: .medium))
                } else {
                    Text("Reading detected!")
                        .foregroundColor(.green)
                        .font(.system(size: 14, weight: .medium))
                }
            } else {
                Image(systemName: hasStoredImage ? "checkmark.circle.fill" : "camera.circle")
                    .foregroundColor(hasStoredImage ? .green : .gray)
                Text(hasStoredImage ? "Photo Saved" : "No Photo")
                    .foregroundColor(hasStoredImage ? .green : .gray)
            }
        }
        .padding(.top, 4)
    }
    
    private var capturedImagePreview: some View {
        Group {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
            }
        }
    }
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "001830"),
                        Color(hex: "000C18")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(WeavePattern()) // Using centralized WeavePattern
                .ignoresSafeArea()
                
        ScrollView {
                    if isLandscape {
                        HStack(alignment: .top, spacing: 16) {
                            VStack(spacing: 16) {
                                testTypeSection
                                meterReadingsSection
                                testParametersSection
                            }
                            .frame(maxWidth: .infinity)
                            
                            VStack(spacing: 16) {
                                meterDetailsSection
                                additionalDetailsSection
                                notesSection
                                recordTestSection
                                recentTestSection
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                    } else {
                        VStack(spacing: 16) {
                            testTypeSection
                            meterReadingsSection
                            testParametersSection
                            meterDetailsSection
                            additionalDetailsSection
                            notesSection
                            recordTestSection
                            recentTestSection
                        }
                        .padding()
                    }
        }
                // Existing modifiers remain unchanged
                .safeAreaInset(edge: .bottom) { Color.clear.frame(height: keyboardHeight) }
                .onChange(of: isNotesFieldFocused) { focused in
                    if focused {
                        withAnimation { scrollProxy.scrollTo("notesSection", anchor: .top) }
                    }
                }
                .simultaneousGesture(
                    DragGesture().onChanged { _ in
                        if keyboardHeight > 0 {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                )
            }
            // Rest of the existing view modifiers remain the same...
        }
        .onAppear {
            let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                    withAnimation {
                        keyboardHeight = keyboardSize.height
                        if self.focusedField == .additionalRemarks {
                            self.isNotesFieldFocused = true
                        }
                    }
                }
            }
            notificationCenter.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                withAnimation {
                    keyboardHeight = 0
                    isNotesFieldFocused = false
                }
            }
        }
        .onChange(of: focusedField) { newValue in
            isNotesFieldFocused = (newValue == .additionalRemarks)
        }
        .sheet(item: $selectedImageSource) { source in
            ImagePicker(sourceType: source.uiImagePickerSourceType, selectedImage: $capturedImage, imageData: $capturedImageData)
                .onDisappear {
                    
                    hasStoredImage = capturedImage != nil
                    selectedImageSource = nil
                    if let image = capturedImage {
                        withAnimation { isProcessingImage = true }
                        self.performBasicOCR(for: image) { success in
                            if success {
                                withAnimation {
                                    isProcessingImage = false
                                    showDetectionSuccess = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { self.showDetectionSuccess = false }
                                }
                            } else {
                                OCRManager.shared.recognizeText(in: image) { text in
                                    withAnimation { isProcessingImage = false }
                                    if let text = text {
                                        self.processFallbackOCR(text)
                                    }
                                }
                            }
                        }
                    }
                }
        }
        .gesture(
            TapGesture().onEnded { _ in
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        )
        .ignoresSafeArea(.keyboard, edges: .bottom)
 
        .overlay(
            Group {
                if isRecordSuccess {
                    TestRecordedNotification()
                        .padding(.top, 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            },
            alignment: .top
        )
    }
    
    // MARK: - Helper Function for Fallback OCR Processing
    private func processFallbackOCR(_ text: String) {
        let nsString = text as NSString
        var bestMeterReading: String? = nil
        let decimalPattern = "\\b\\d+\\.\\d+\\b"
        if let regex = try? NSRegularExpression(pattern: decimalPattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            for match in matches {
                let matchString = nsString.substring(with: match.range)
                let surroundRange = NSRange(location: max(0, match.range.location - 1),
                                            length: min(nsString.length - match.range.location + 1, match.range.length + 2))
                let surroundText = nsString.substring(with: surroundRange)
                if surroundText.rangeOfCharacter(from: CharacterSet(charactersIn: "#@$%^&*+=<>{}[]|\\:;")) == nil,
                   let value = Double(matchString), value > 0 {
                    bestMeterReading = matchString
                    print("Found meter reading with decimal: \(matchString)")
                    break
                }
            }
        }
        if bestMeterReading == nil {
            let gallonsPattern = "(\\d+(?:,\\d{3})*(?:\\.\\d+)?)(?=\\s*(?:gal(?:lon)?s?))"
            if let regex = try? NSRegularExpression(pattern: gallonsPattern, options: .caseInsensitive) {
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
                if let match = matches.first {
                    let matchString = nsString.substring(with: match.range)
                    bestMeterReading = matchString.replacingOccurrences(of: ",", with: "")
                    print("Found numeric preceding 'gal/gallon/gallons': \(matchString) normalized to \(bestMeterReading!)")
                }
            }
        }
        if bestMeterReading == nil {
            let digitPattern = "\\b\\d{5,8}\\b"
            if let regex = try? NSRegularExpression(pattern: digitPattern, options: []) {
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
                for match in matches {
                    let matchString = nsString.substring(with: match.range)
                    let surroundRange = NSRange(location: max(0, match.range.location - 1),
                                                length: min(nsString.length - match.range.location + 1, match.range.length + 2))
                    let surroundText = nsString.substring(with: surroundRange)
                    let hasSpecialChar = surroundText.rangeOfCharacter(from: CharacterSet(charactersIn: "#@$%^&*+=<>{}[]|\\:;")) != nil
                    if !hasSpecialChar, let value = Double(matchString), value > 0 {
                        bestMeterReading = matchString
                        print("Found digit sequence as meter reading: \(matchString)")
                        break
                    }
                }
            }
        }
        if bestMeterReading == nil {
            let potentialDecimalPattern = "\\b(\\d+)\\s+(\\d{1,3})\\b"
            if let regex = try? NSRegularExpression(pattern: potentialDecimalPattern, options: []) {
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
                for match in matches {
                    if match.numberOfRanges >= 3 {
                        let wholePart = nsString.substring(with: match.range(at: 1))
                        let decimalPart = nsString.substring(with: match.range(at: 2))
                        if decimalPart.count <= 3 {
                            let combined = "\(wholePart).\(decimalPart)"
                            bestMeterReading = combined
                            print("Reconstructed decimal reading: \(combined)")
                            break
                        }
                    }
                }
            }
        }
        // Extract serial number using helper
        if let serial = self.extractSerialNumber(from: text) {
            self.jobNumberText = serial
            print("Extracted serial number: \(serial)")
        }
        DispatchQueue.main.async {
            if let reading = bestMeterReading {
                if self.selectedSingleMeter == .small {
                    self.viewModel.smallMeterStart = reading
                } else {
                    self.viewModel.largeMeterStart = reading
                }
            }
            self.viewModel.notes += "\n\(text)"
        }
    }
    
    // MARK: - Helper Method: Extract Serial Number from Text
    private func extractSerialNumber(from text: String) -> String? {
        let serialPattern = "\\b[A-Za-z0-9]{5,15}\\b"
        guard let regex = try? NSRegularExpression(pattern: serialPattern, options: [.caseInsensitive]) else { return nil }
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        for match in matches {
            let matchString = nsString.substring(with: match.range)
            let specialChars = CharacterSet(charactersIn: "#@$%^&*+=<>{}[]|\\:;/")
            if matchString.rangeOfCharacter(from: specialChars) == nil {
                let hasLetters = matchString.rangeOfCharacter(from: .letters) != nil
                let hasDigits = matchString.rangeOfCharacter(from: .decimalDigits) != nil
                if (hasLetters && hasDigits) || (matchString.count >= 5 && !matchString.contains(".")) {
                    return matchString
                }
            }
        }
        return nil
    }
}

// MARK: - VisualEffectBlur for glassmorphism effect
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) { }
}
 
// ADD: Particle emitter view
private struct ParticleEmitterView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        // Check if Spark image exists, otherwise use a fallback
        let sparkImage = UIImage(named: "Spark")?.cgImage

        let size = UIScreen.main.bounds.size
        let host = UIView(frame: CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
        
        let particlesLayer = CAEmitterLayer()
        particlesLayer.frame = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        
        host.layer.addSublayer(particlesLayer)
        host.layer.masksToBounds = true
        
        particlesLayer.backgroundColor = UIColor.clear.cgColor
        particlesLayer.emitterShape = .point
        // Position emitter slightly above center to originate near the notification
        particlesLayer.emitterPosition = CGPoint(x: size.width / 2, y: {
            let window = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.windows.first
            return (window?.safeAreaInsets.top ?? 20) + 40
        }())
        particlesLayer.emitterSize = CGSize(width: 0.0, height: 0.0)
        particlesLayer.emitterMode = .outline
        particlesLayer.renderMode = .additive
        
        // Parent cell (invisible, controls burst timing/position)
        let parentCell = CAEmitterCell()
        parentCell.name = "Parent"
        parentCell.birthRate = 1.0
        parentCell.lifetime = 0.1
        parentCell.velocity = 0
        parentCell.emissionRange = .pi * 2
        parentCell.scale = 0.0

        // Trail subcell (the visible spark)
        let trailCell = CAEmitterCell()
        trailCell.contents = sparkImage
        trailCell.name = "Trail"
        trailCell.birthRate = 150.0
        trailCell.lifetime = 1.5
        trailCell.lifetimeRange = 0.5
        trailCell.beginTime = 0.01
        trailCell.velocity = 150.0
        trailCell.velocityRange = 50.0
        trailCell.xAcceleration = 0
        trailCell.yAcceleration = 300.0
        trailCell.emissionLongitude = -.pi / 2
        trailCell.emissionRange = .pi / 4
        trailCell.scale = 0.4
        trailCell.scaleRange = 0.2
        trailCell.scaleSpeed = -0.3
        trailCell.alphaSpeed = -0.8
        trailCell.spin = .pi * 2
        trailCell.spinRange = .pi
        trailCell.color = UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0).cgColor
        trailCell.redRange = 0.3
        trailCell.greenRange = 0.3
        trailCell.blueRange = 0.2

        // Assign trailCell as the subcell of parentCell
        parentCell.emitterCells = [trailCell]
        particlesLayer.emitterCells = [parentCell]

        if sparkImage == nil {
            print("Warning: Spark image not found for ParticleEmitterView.")
        }
        
        return host
    }

    func updateUIView(_ uiView: UIView, context: Context) {
    }
}
// Rmoved the duplicate ParticleEmitterView struct definition that was here.
    
    
    // MARK: - TestRecordedNotification View
    struct TestRecordedNotification: View {
        @State private var showFireworks = true
        
        var body: some View {
            ZStack {
                VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(gradient: Gradient(colors: [Color("AccentColorLight"), Color("AccentColorDark")]),
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing))
                    .opacity(0.85)
                    .blendMode(.overlay)
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
                    Text("Test Recorded Successfully")
                        .font(.headline)
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                // Conditionally show Fireworks overlay
                if showFireworks {
                    ParticleEmitterView()
                        .allowsHitTesting(false)
                        .transition(.opacity.animation(.easeIn(duration: 0.5))) // Optional fade in/out
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.top, {
                let window = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?.windows.first
                return (window?.safeAreaInsets.top ?? 20) + 16
            }())
            .transition(.move(edge: .top).combined(with: .opacity))
            .zIndex(1)
            .onAppear {
                // Trigger fireworks on appear
                withAnimation {
                    showFireworks = true
                }
                // Hide fireworks after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { // Reduced duration
                    withAnimation {
                        showFireworks = false
                    }
                }
            }
        }
    }
    
    // MARK: - Extension to make UIImagePickerController.SourceType Identifiable
    enum PickerSource: Int, Identifiable {
        case camera
        case photoLibrary
        case savedPhotosAlbum
    
        var id: Int { self.rawValue }
        
        var uiImagePickerSourceType: UIImagePickerController.SourceType {
            switch self {
            case .camera:
                return .camera
            case .photoLibrary:
                return .photoLibrary
            case .savedPhotosAlbum:
                return .savedPhotosAlbum
            }
        }
    }
