
import SwiftUI
import PhotosUI
import BackgroundTasks

class UploadManager: NSObject, ObservableObject {
    static let shared = UploadManager()
    private var backgroundSession: URLSession!
    @Published var uploadStatuses: [UploadStatus] = []
    @Published var successCount = 0
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.whatoutfit.upload")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        backgroundSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    func uploadImage(status: UploadStatus, phoneNumber: String) async {
        do {
            guard let data = try await status.item.loadTransferable(type: Data.self) else {
                throw URLError(.badServerResponse)
            }
            
            // Create a temporary file to store the upload data
            let tempDirectoryURL = FileManager.default.temporaryDirectory
            let fileURL = tempDirectoryURL.appendingPathComponent(UUID().uuidString)
            
            // Create the JSON payload
            let base64String = data.base64EncodedString()
            let bodyData: [String: String] = [
                "image_content": base64String,
                "from_number": phoneNumber
            ]
            let jsonData = try JSONSerialization.data(withJSONObject: bodyData)
            
            // Write the JSON data to the temporary file
            try jsonData.write(to: fileURL)
            
            let urlString = "https://app.wha7.com/ios"
            guard let url = URL(string: urlString) else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Create background upload task using the file
            let task = backgroundSession.uploadTask(with: request, fromFile: fileURL)
            task.taskDescription = "\(status.id)"
            task.resume()
            
        } catch {
            await MainActor.run {
                print("Upload failed for Image \(status.orderNumber): \(error.localizedDescription)")
            }
        }
    }
}

// Add URLSession delegate conformance
extension UploadManager: URLSessionDelegate, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("Upload task failed: \(error)")
            } else {
                if let taskDescription = task.taskDescription,
                   let id = UUID(uuidString: taskDescription),
                   let index = uploadStatuses.firstIndex(where: { $0.id == id }) {
                    uploadStatuses[index].isComplete = true
                    successCount += 1
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("Session became invalid with error: \(String(describing: error))")
    }
}

struct UploadStatus: Identifiable {
    let id: UUID
    let item: PhotosPickerItem
    let orderNumber: Int
    var isComplete: Bool = false
}

