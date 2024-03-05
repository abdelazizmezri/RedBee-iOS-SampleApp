import AVFoundation
import GoogleCast
import iOSClientExposure

class QRScannerViewModel: NSObject {
    
    private let jsPlayerURL = "https://ericssonbroadcastservices.github.io/javascript-player/?"
    private var session: AVCaptureSession = AVCaptureSession()
    private var isScanning = true
    
    public override init() {
        super.init()
    }
    
    func tryToStartSession() {
        if session.isRunning == false {
            let queue = DispatchQueue.global(qos: .background)
            queue.async { [weak self] in
                self?.session.startRunning()
            }
            isScanning = true
        }
    }
    
    func tryToStopSession() {
        if session.isRunning == true {
            session.stopRunning()
        }
    }
    
    func createSession(
        rectOfInterest: CGRect
    ) -> AVCaptureSession? {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return nil }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            session.addInput(input)
        } catch {
            print(error.localizedDescription)
            return nil
        }
        
        let output = createAVCaptureMetadataOutput(rectOfInterest: rectOfInterest)
        session.addOutput(output)
        output.metadataObjectTypes = [.qr]
        
        return session
    }
    
    func createAVCaptureMetadataOutput(
        rectOfInterest: CGRect
    ) -> AVCaptureMetadataOutput {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        let output = AVCaptureMetadataOutput()
        
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        output.rectOfInterest = CGRect(
            x: rectOfInterest.origin.y / screenHeight,
            y: rectOfInterest.origin.x / screenWidth,
            width: rectOfInterest.size.height / screenHeight,
            height: rectOfInterest.size.width / screenWidth
        )
        return output
    }
    
}

// MARK: - AVFoundation QR
extension QRScannerViewModel: AVCaptureMetadataOutputObjectsDelegate {
    internal func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        if isScanning {
            isScanning = false
            if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject {
                if metadataObject.type == .qr {
                    if let qrCodeData = metadataObject.stringValue {
                        let parameters = extractURLParameters(from: qrCodeData)
                        navigateWithQRParams(qrParams: parameters)
                        session.stopRunning()
                        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                    }
                }
            }
        }
    }
}

// MARK: - private functions
extension QRScannerViewModel {
    
    func extractURLParameters(from qrCodeData: String) -> QRCodeURLParameters {
        var parameters = QRCodeURLParameters()
        
        if let url = URL(string: qrCodeData) {
            if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
                for queryItem in queryItems {
                    if let value = queryItem.value {
                        if let parameter = QRCodeParameter(rawValue: queryItem.name) {
                            switch parameter {
                            case .env: parameters.env = value
                            case .cu: parameters.cu = value
                            case .bu: parameters.bu = value
                            case .source: parameters.source = value
                            case .sessionToken: parameters.sessionToken = value
                            }
                        }
                    }
                }
            }
        }
        
        return parameters
    }
    
    private func navigateWithQRParams(qrParams: QRCodeURLParameters) {
 
        guard
            let baseUrl = qrParams.env,
            let customer = qrParams.cu,
            let businessUnit = qrParams.bu
        else {
            /// 1. Try to fill any Env fields if available
            if [qrParams.env, qrParams.cu, qrParams.bu].contains(where: { $0 != nil }) {
                StorageProvider.store(
                    environment: Environment(
                        baseUrl: qrParams.env ?? "",
                        customer: qrParams.cu ?? "",
                        businessUnit: qrParams.bu ?? ""
                    )
                )
            }
            reloadAppNavigation(qrParams: qrParams)
            return
        }
        
        let environment = Environment(
            baseUrl: baseUrl,
            customer: customer,
            businessUnit: businessUnit
        )
            
        if let sessionToken = SessionToken(value: qrParams.sessionToken) {
            /// 2. If sessionToken is provided always validate it
            validateSessionToken(
                sessionToken: sessionToken,
                qrParams: qrParams,
                environment: environment
            )
        } else {
            /// 3. Try to login anonymously if Env data available and no session token
            anonymousLogin(
                qrParams: qrParams,
                environment: environment
            )
        }
            
    }
    
    private func validateSessionToken(
        sessionToken: SessionToken,
        qrParams: QRCodeURLParameters,
        environment: Environment
    ) {
        Authenticate(environment: environment)
            .validate(sessionToken: SessionToken(value: sessionToken.value))
            .request()
            .validate()
            .response {
                var errorModel: ErrorModel? = nil
                if let error = $0.error {
                    errorModel = ErrorModel(error: error)
                } else if $0.value != nil {
                    StorageProvider.store(environment: environment)
                    StorageProvider.store(sessionToken: sessionToken)
                }
                
                reloadAppNavigation(
                    qrParams: qrParams,
                    error: errorModel
                )
            }
    }
    
    private func anonymousLogin(
        qrParams: QRCodeURLParameters,
        environment: Environment
    ) {
        Authenticate(environment: environment)
            .anonymous()
            .request()
            .validate()
            .response {
                var errorModel: ErrorModel? = nil
                if let error = $0.error {
                    errorModel = ErrorModel(error: error)
                } else if let credentials = $0.value {
                    StorageProvider.store(environment: environment)
                    StorageProvider.store(sessionToken: credentials.sessionToken)
                }
                reloadAppNavigation(
                    qrParams: qrParams,
                    error: errorModel
                )
            }
    }
}
