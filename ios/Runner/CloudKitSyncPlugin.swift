import Flutter
import CloudKit

/// Platform channel plugin for CloudKit sync operations.
/// Uploads/downloads a JSON snapshot blob to the user's private CloudKit database.
class CloudKitSyncPlugin: NSObject, FlutterPlugin {
    private static let channelName = "com.repfoundry.app/cloudkit_sync"
    private static let containerIdentifier = "iCloud.com.repfoundry.app"
    private static let recordType = "SyncSnapshot"
    private static let recordId = "repfoundry_sync"
    private static let jsonField = "jsonData"

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = CloudKitSyncPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isAvailable":
            checkAvailability(result: result)
        case "uploadSnapshot":
            guard let args = call.arguments as? [String: Any],
                  let json = args["json"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing json argument", details: nil))
                return
            }
            uploadSnapshot(json: json, result: result)
        case "downloadSnapshot":
            downloadSnapshot(result: result)
        case "deleteCloudData":
            deleteCloudData(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - CloudKit Operations

    private func checkAvailability(result: @escaping FlutterResult) {
        CKContainer(identifier: CloudKitSyncPlugin.containerIdentifier)
            .accountStatus { status, error in
                DispatchQueue.main.async {
                    if let error = error {
                        result(FlutterError(code: "CLOUDKIT_ERROR", message: error.localizedDescription, details: nil))
                    } else {
                        result(status == .available)
                    }
                }
            }
    }

    private func uploadSnapshot(json: String, result: @escaping FlutterResult) {
        let container = CKContainer(identifier: CloudKitSyncPlugin.containerIdentifier)
        let database = container.privateCloudDatabase
        let recordId = CKRecord.ID(recordName: CloudKitSyncPlugin.recordId)

        // Fetch existing record to update, or create new
        database.fetch(withRecordID: recordId) { existingRecord, error in
            let record: CKRecord
            if let existing = existingRecord {
                record = existing
            } else {
                record = CKRecord(recordType: CloudKitSyncPlugin.recordType, recordID: recordId)
            }

            // Write JSON to a temporary file as CKAsset
            let tempDir = FileManager.default.temporaryDirectory
            let tempFile = tempDir.appendingPathComponent("repfoundry_sync.json")
            do {
                try json.write(to: tempFile, atomically: true, encoding: .utf8)
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "FILE_ERROR", message: error.localizedDescription, details: nil))
                }
                return
            }

            record[CloudKitSyncPlugin.jsonField] = CKAsset(fileURL: tempFile)

            database.save(record) { _, saveError in
                // Clean up temp file
                try? FileManager.default.removeItem(at: tempFile)

                DispatchQueue.main.async {
                    if let saveError = saveError {
                        result(FlutterError(code: "UPLOAD_ERROR", message: saveError.localizedDescription, details: nil))
                    } else {
                        result(true)
                    }
                }
            }
        }
    }

    private func downloadSnapshot(result: @escaping FlutterResult) {
        let container = CKContainer(identifier: CloudKitSyncPlugin.containerIdentifier)
        let database = container.privateCloudDatabase
        let recordId = CKRecord.ID(recordName: CloudKitSyncPlugin.recordId)

        database.fetch(withRecordID: recordId) { record, error in
            DispatchQueue.main.async {
                if let error = error as? CKError, error.code == .unknownItem {
                    // No snapshot exists yet
                    result(nil)
                    return
                }
                if let error = error {
                    result(FlutterError(code: "DOWNLOAD_ERROR", message: error.localizedDescription, details: nil))
                    return
                }
                guard let record = record,
                      let asset = record[CloudKitSyncPlugin.jsonField] as? CKAsset,
                      let fileURL = asset.fileURL else {
                    result(nil)
                    return
                }
                do {
                    let json = try String(contentsOf: fileURL, encoding: .utf8)
                    result(json)
                } catch {
                    result(FlutterError(code: "READ_ERROR", message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    private func deleteCloudData(result: @escaping FlutterResult) {
        let container = CKContainer(identifier: CloudKitSyncPlugin.containerIdentifier)
        let database = container.privateCloudDatabase
        let recordId = CKRecord.ID(recordName: CloudKitSyncPlugin.recordId)

        database.delete(withRecordID: recordId) { _, error in
            DispatchQueue.main.async {
                if let error = error as? CKError, error.code == .unknownItem {
                    // Nothing to delete — that's fine
                    result(true)
                    return
                }
                if let error = error {
                    result(FlutterError(code: "DELETE_ERROR", message: error.localizedDescription, details: nil))
                } else {
                    result(true)
                }
            }
        }
    }
}
