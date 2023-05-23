import SwiftUI
import UIKit
import CoreData

struct ContentView: View {
    @State private var phoneNumber: String = ""
    @State private var firstName: String = ""
    @State private var profilePicture: String = ""
    @State private var progress: Float = 0.0
    
    var body: some View {
        NavigationView {
            ZStack {
                ProgressBar(progress: $progress)
                    .padding(.bottom, 750)
                VStack {
                    
                    if progress == 0.0 {
                        PhoneNumberView(phoneNumber: $phoneNumber, progress: $progress)
                    } else if progress == 0.5 {
                        FirstNameView(firstName: $firstName, progress: $progress)
                    } else if progress == 1.0 {
                        ProfilePictureView(profilePicture: $profilePicture, phoneNumber: $phoneNumber, firstName: $firstName, progress: $progress)
                    }
                }
                .padding()
                .navigationBarItems(leading: progress > 0.0 ? backButton : nil)
                
            }
        }
            }
    
    private var backButton: some View {
        Button(action: {
            if progress == 0.0 {
                // navigation back action
            } else if progress == 0.5 {
                progress -= 0.5
            } else if progress == 1.0 {
                progress -= 0.5
            }
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.blue)
                .imageScale(.large)
        }
    }
}

struct PhoneNumberView: View {
    @Binding var phoneNumber: String
    @Binding var progress: Float
    
    var body: some View {
        VStack {
            Text("What's your phone number?")
                .font(.title)
                .padding()
            Text("You'll get an OTP. Your number is not visible to others.")
            
            TextField("Phone Number", text: $phoneNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                if validatePhoneNumber() {
                    progress += 0.5
                }
            }) {
                Text("Next")
                    .font(.headline)
                    .padding()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
    
    private func validatePhoneNumber() -> Bool {
        // Performing validation for phone number
        guard !phoneNumber.isEmpty else {
            return false
        }
        guard phoneNumber.count == 10, phoneNumber.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil else {
            return false
        }
        return true // Return true if valid, false otherwise
    }
}

struct FirstNameView: View {
    @Binding var firstName: String
    @Binding var progress: Float
    
    var body: some View {
        VStack {
            Text("What's your first name?")
                .font(.title)
                .padding()
            
            TextField("First Name", text: $firstName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                if validateFirstName() {
                    progress += 0.5
                }
            }) {
                Text("Next")
                    .font(.headline)
                    .padding()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
    
    private func validateFirstName() -> Bool {
        // Performing validation for first name
        guard !firstName.isEmpty else {
            return false
        }
        return true // Return true if valid, false otherwise
    }
}


struct ProfilePictureView: View {
    @Binding var profilePicture: String
    @Binding var phoneNumber: String
    @Binding var firstName: String
    @Binding var progress: Float
    @State private var selectedImage: UIImage?
    @State private var showImagePicker: Bool = false
    
    var body: some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.width * 0.8)
                        .cornerRadius(10)
                    
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                    .padding(8)
                    .offset(x: -8, y: 8)
                } else {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Text("Select Picture")
                            .font(.headline)
                            .padding()
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            
            Button(action: {
                if validateProfilePicture() {
                    saveDataToCoreData()
                    progress = 0.0
                }
            }) {
                Text("Finish")
                    .font(.headline)
                    .padding()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .sheet(isPresented: $showImagePicker, onDismiss: loadImage) {
            ImagePicker(image: $selectedImage)
        }
    }
    
    private func validateProfilePicture() -> Bool {
        // Perform profile picture validation here
        return selectedImage != nil // Return true if image is selected, false otherwise
    }
    
    private func saveDataToCoreData() {
        guard let image = selectedImage else {
            return
        }
        
        // Converting the UIImage to Data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        // Encoding the image data as Base64
        let base64String = imageData.base64EncodedString()
        
        // Saving the image data as a string to Core Data
        let context = CoreDataManager.shared.mainContext
        let profile = Profile(context: context)
        profile.phoneNumber = phoneNumber
        profile.firstName = firstName
        profile.profilePicture = base64String
        
        CoreDataManager.shared.saveContext()
    }
    
    private func loadImage() {
        guard let selectedImage = selectedImage else { return }
        
        // Updating the profile picture
        profilePicture = "\(selectedImage)"
    }
}


struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        @Binding var presentationMode: PresentationMode
        @Binding var image: UIImage?
        
        init(presentationMode: Binding<PresentationMode>, image: Binding<UIImage?>) {
            _presentationMode = presentationMode
            _image = image
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                image = uiImage
            }
            
            presentationMode.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            presentationMode.dismiss()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(presentationMode: presentationMode, image: $image)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController,
                                context: UIViewControllerRepresentableContext<ImagePicker>) {}
}


struct ProgressBar: View {
    @Binding var progress: Float
    
    var body: some View {
        HStack {
            Spacer()
            ProgressView(value: progress, total: 1.0)
                .frame(width: UIScreen.main.bounds.width * 0.7)
            Spacer()
        }
    }
}


