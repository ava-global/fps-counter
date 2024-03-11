//
//  FPSStatusBarViewController.swift
//  fps-counter
//
//  Created by Markus Gasser on 04.03.16.
//  Copyright © 2016 konoma GmbH. All rights reserved.
//

import UIKit


/// A view controller to show a FPS label in the status bar.
///
class FPSStatusBarViewController: UIViewController {

    fileprivate let fpsCounter = FPSCounter()
    private let label = UILabel()


    // MARK: - Initialization

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        self.commonInit()
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)

        self.commonInit()
    }

    private func commonInit() {
        NotificationCenter.default.addObserver(self,
            selector: #selector(FPSStatusBarViewController.updateStatusBarFrame(_:)),
            name: UIApplication.didChangeStatusBarOrientationNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }


    // MARK: - View Lifecycle and Events

    override func loadView() {
        self.view = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 100.0, height: 100.0))

        let font = UIFont.boldSystemFont(ofSize: 10.0)
        let rect = self.view.bounds.insetBy(dx: 10.0, dy: 0.0)

        self.label.frame = CGRect(x: rect.origin.x, y: rect.maxY - font.lineHeight - 1.0, width: rect.width, height: font.lineHeight)
        self.label.autoresizingMask = [ .flexibleWidth, .flexibleTopMargin ]
        self.label.font = font
        self.view.addSubview(self.label)

        self.fpsCounter.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateStatusBarFrame()
    }

    @objc func updateStatusBarFrame(_ notification: Notification? = nil) {
        if let windowScene = self.view.window?.windowScene {
            self.view.frame = windowScene.statusBarManager?.statusBarFrame ?? CGRect.zero
        }
    }


    // MARK: - Getting the shared status bar window

    @objc static var statusBarWindow: UIWindow = {
        let window = FPStatusBarWindow()
        window.windowLevel = .statusBar
        window.rootViewController = FPSStatusBarViewController()
        return window
    }()
}


// MARK: - FPSCounterDelegate

extension FPSStatusBarViewController: FPSCounterDelegate {

    @objc func fpsCounter(_ counter: FPSCounter, didUpdateFramesPerSecond fps: Int) {
        self.resignKeyWindowIfNeeded()

        let milliseconds = 1000 / max(fps, 1)
        self.label.text = "\(fps) FPS (\(milliseconds) ms/f)"

        switch fps {
        case 45...:
            self.view.backgroundColor = .green
            self.label.textColor = .black
        case 35...:
            self.view.backgroundColor = .orange
            self.label.textColor = .white
        default:
            self.view.backgroundColor = .red
            self.label.textColor = .white
        }
    }

    private func resignKeyWindowIfNeeded() {
        // prevent the status bar window from becoming the key window and steal events
        // from the main application window
        if FPSStatusBarViewController.statusBarWindow.isKeyWindow {
            UIApplication.shared.delegate?.window??.makeKey()
        }
    }
}


public extension FPSCounter {
    @objc static var statusBarWindow: UIWindow?
    
    // This function is responsible for creating the status bar window
    // It now uses the window scene for iOS 13 and later
    static func createStatusBarWindow() {
        // Check if we can get the window scene
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        
        let window = FPStatusBarWindow(windowScene: windowScene)
        window.windowLevel = .statusBar + 1
        window.rootViewController = FPSStatusBarViewController()
        window.frame = windowScene.statusBarManager?.statusBarFrame ?? CGRect.zero
        statusBarWindow = window
    }

    
    // MARK: - Show FPS in the status bar

    /// Add a label in the status bar that shows the applications current FPS.
    ///
    /// - Note:
    ///   Only do this in debug builds. Apple may reject your app if it covers the status bar.
    ///
    /// - Parameters:
    ///   - application: The `UIApplication` to show the FPS for
    ///   - runloop:     The `NSRunLoop` to use when tracking FPS. Default is the main run loop
    ///   - mode:        The run loop mode to use when tracking. Default uses `RunLoop.Mode.common`
    ///
    @objc class func showInStatusBar(
        application: UIApplication = .shared,
        runloop: RunLoop = .main,
        mode: RunLoop.Mode = .common
    ) {
        // Ensure the status bar window is created
        if statusBarWindow == nil {
            createStatusBarWindow()
        }
        
        guard let window = statusBarWindow else { return }
        window.isHidden = false

        if let controller = window.rootViewController as? FPSStatusBarViewController {
            controller.fpsCounter.startTracking(
                inRunLoop: .main,
                mode: .common
            )
        }
    }

    /// Removes the label that shows the current FPS from the status bar.
    ///
    @objc class func hide() {
        let window = FPSStatusBarViewController.statusBarWindow

        if let controller = window.rootViewController as? FPSStatusBarViewController {
            controller.fpsCounter.stopTracking()
            window.isHidden = true
        }
    }

    /// Returns wether the FPS counter is currently visible or not.
    ///
    @objc class var isVisible: Bool {
        return !FPSStatusBarViewController.statusBarWindow.isHidden
    }
}
