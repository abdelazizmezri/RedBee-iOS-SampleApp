import UIKit
import AVFoundation

class QRScannerViewController: UIViewController {

    var viewModel: QRScannerViewModel
    
    public init(
        viewModel: QRScannerViewModel
    ) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let rectOfInterest = createRectOfInterest()
        
        guard
            let session = viewModel.createSession(rectOfInterest: rectOfInterest)
        else {
            return
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        setupLayout(rectOfInterest: rectOfInterest)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.tryToStartSession()
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        viewModel.tryToStopSession()
    }
    
}

// MARK: - private functions
extension QRScannerViewController {
    
    private func createRectOfInterest() -> CGRect {
           let screenWidth = UIScreen.main.bounds.width
           let screenHeight = UIScreen.main.bounds.height
           
           return CGRect(
               x: (screenWidth - 200) / 2,
               y: (screenHeight - 200) / 2,
               width: 200,
               height: 200
           )
       }
    
    private func setupLayout(
        rectOfInterest: CGRect
    ) {
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.addSubview(overlayView)

        let squareView = UIView(frame: rectOfInterest)
        squareView.layer.borderWidth = 2
        squareView.backgroundColor = UIColor.clear
        view.addSubview(squareView)

        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(rect: overlayView.bounds)
        path.append(UIBezierPath(rect: squareView.frame).reversing())
        maskLayer.path = path.cgPath
        overlayView.layer.mask = maskLayer
    }
    
}
