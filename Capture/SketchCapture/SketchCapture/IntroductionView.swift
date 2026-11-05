//
//  IntroductionView.swift
//  SketchCapture
//
//  Created by Daniel Leivers on 28/04/2023.
//

import SwiftUI
import FirebaseAuth
import FirebaseStorage

struct IntroductionView: View {
    @ObservedObject var viewModel: ViewModel

    @State var isPresentingGenerationView = false

    var body: some View {
        NavigationStack {
            if viewModel.isLoading {
                ProgressView()
            }
            else if let start = viewModel.startingSketch {
                VStack(alignment: HorizontalAlignment.leading) {
                    Spacer()
                    HStack {
                        Text("Your name:")
                        TextField("Name (optional)", text: $viewModel.usersName)
                    }.padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                    .background(RoundedRectangle(cornerRadius: 20).fill(.clear).border(Color.black, width: 2))
                    VStack(alignment: HorizontalAlignment.leading) {
                        Text("Terms and conditions").font(.title)
                        Text("This app captures your sketches and asks you to label each element. The data captured will be used for training a model for classification. Your name is captured for the purposes of ensuring your consent to this form and will not be used in the training of the model - however you can choose not to provide your name. You can withdraw at any point.")
                        Toggle(isOn: $viewModel.hasUserAgreed) {
                            Text("Do you agree to these terms?").bold()
                        }
                        Text("Participants can be 'debriefed' at the end of the study if desired.")
                        Toggle(isOn: $viewModel.hasRequestedDebrief) {
                            Text("Would you like to be debriefed?").bold()
                        }
                        Text("We may require a number of participants to help evaulate the results, would you be open to this?")
                        Toggle(isOn: $viewModel.hasAgreedToEvaluation) {
                            Text("I would/wouldn't be open to the evaluation.").bold()
                        }
                        HStack {
                            Button("Capture", action: {
                                viewModel.submitForm()
                            })
                            .frame(width: .infinity, alignment: .center)
                            .buttonStyle(.borderedProminent)
                            .disabled(!viewModel.canProceed)
                            .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
                            Button("Draw", action: {
                                viewModel.submitFormForDrawing()
                            })
                            .frame(width: .infinity, alignment: .center)
                            .buttonStyle(.borderedProminent)
                            .disabled(!viewModel.canProceed)
                            .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
                        }
                    }
                    Spacer(minLength: 10)
//                    Button("Show Generated") {
//                        isPresentingGenerationView = true
//                    }
                    Spacer(minLength: 10)
                    HStack {
                        Text("Total sketches:").font(.footnote)
                        Text(String(viewModel.sketchCount)).font(.footnote)
                    }
                }
                .padding(EdgeInsets(top: 20, leading: 80, bottom: 20, trailing: 80))
                .fullScreenCover(isPresented: $viewModel.isPresentingDrawingCaptureView, onDismiss: {
                    viewModel.fetchNewExample()
                    viewModel.fetchCurrentCount()
                }, content: { DrawingView(viewModel: DrawingView.ViewModel(startingSketch: start, userStatement: viewModel.userStatement!)) })
                .fullScreenCover(isPresented: $viewModel.isPresentingDrawingView, onDismiss: {
                    viewModel.fetchNewExample()
                    viewModel.fetchCurrentCount()
                }, content: { DrawingView(viewModel: DrawingView.ViewModel(startingSketch: start, userStatement: viewModel.userStatement!, isCapture: false)) })
                .fullScreenCover(isPresented: $isPresentingGenerationView, onDismiss: {
//                    viewModel.fetchNewExample()
//                    viewModel.fetchCurrentCount()
                    isPresentingGenerationView = false
                }, content: { GeneratedView(viewModel: GeneratedViewViewModel(boxesString: GeneratedView.otherBoundingBoxesString)) })
            }
        }
    }
}

struct IntroductionView_Previews: PreviewProvider {
    static var previews: some View {
        IntroductionView(viewModel: IntroductionView.ViewModel())
    }
}

extension IntroductionView {

    class ViewModel: ObservableObject {
        @Published private(set) var isLoading: Bool = false

        @Published var sketchCount: Int = 0
        @Published var usersName: String = ""
        @Published var hasUserAgreed: Bool = false {
            didSet {
                canProceed = hasUserAgreed
            }
        }
        @Published var hasRequestedDebrief: Bool = false
        @Published var hasAgreedToEvaluation: Bool = false
        @Published var canProceed: Bool = false

        @Published var isPresentingDrawingCaptureView = false
        @Published var isPresentingDrawingView = false

        private(set) var startingSketch: StartingSketch?
        private(set) var userStatement: UserStatement?

        private var currentlyLoading: StorageDownloadTask?

        init() {
            isLoading = true
            Auth.auth().signInAnonymously { [weak self] authResult, error in
                self?.fetchNewExample()
                self?.fetchCurrentCount()
            }
        }

        func fetchNewExample() {
            isLoading = true
            currentlyLoading?.cancel()
            let storage = Storage.storage()
            let storageReference = storage.reference().child("examples")
            storageReference.listAll { [weak self] (result, error) in
                if let items = result?.items {
                    guard let self, let randomScreenshotRef = items.randomElement() else { return }
                    let name = randomScreenshotRef.name
                    let localURL = self.getDocumentsDirectory().appending(path: name)

                    // Download to the local filesystem
                    self.currentlyLoading = randomScreenshotRef.write(toFile: localURL) { [weak self] url, error in
                        if let error = error {
                            // Uh-oh, an error occurred!
                            print("Error: \(error)")
                        } else {
                            self?.startingSketch = StartingSketch(localImage: localURL)
                        }

                        self?.isLoading = false
                    }
                 }
            }
        }

        func fetchCurrentCount() {
            DataStore().countSketches { [weak self] count in
                self?.sketchCount = count ?? 0
            }
        }

        private func getDocumentsDirectory() -> URL {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let documentsDirectory = paths[0]
            return documentsDirectory
        }

        func submitForm() {
            userStatement = UserStatement(name: usersName, hasAgreedToTerms: hasUserAgreed, hasRequestedDebrief: hasRequestedDebrief, hasAgreedToEvaluation: hasAgreedToEvaluation)
            isPresentingDrawingCaptureView = true
        }

        func submitFormForDrawing() {
            userStatement = UserStatement(name: usersName, hasAgreedToTerms: hasUserAgreed, hasRequestedDebrief: hasRequestedDebrief, hasAgreedToEvaluation: hasAgreedToEvaluation)
            isPresentingDrawingView = true
        }
    }
}
