//
//  ScanPreviewViewController.swift
//  DepthRenderer
//
//  Created by Aaron Thompson on 5/11/18.
//  Copyright © 2019 Standard Cyborg. All rights reserved.
//


//------------------\\
//   Ashley Edits   \\
//------------------\\
// Changed _quickLookUSDZURL --> _quickLookOBJURL
// Changed tempUSDZPath --> tempOBJPath
// Changed mesh.writeToUSDZ(atPath: tempUSDZPath) --> mesh.writeToOBJZip(atPath: tempOBJPath)
// Changed _shouldExportToUSDZ --> _shouldExportToOBJ


import Foundation
import ModelIO
import QuickLook
import StandardCyborgFusion
import SceneKit
import UIKit

class ScanPreviewViewController: UIViewController, QLPreviewControllerDataSource {
    
    // MARK: - IB Outlets and Actions
    
    @IBOutlet private weak var sceneView: SCNView!
    @IBOutlet private weak var meshButton: UIButton!
    @IBOutlet private weak var meshingProgressContainer: UIView!
    @IBOutlet private weak var meshingProgressView: UIProgressView!
    private var _quickLookOBJURL: URL?
    
    @IBAction private func _export(_ sender: AnyObject) {
        if let scan = scan {
            let shareURL: URL?
            
            if _shouldExportToOBJ {
                if let mesh = _mesh {
                    let tempOBJPath = NSTemporaryDirectory().appending("/mesh.zip")
                    
                    try? FileManager.default.removeItem(atPath: tempOBJPath)
                    mesh.writeToOBJZip(atPath: tempOBJPath)
                    
                    shareURL = URL(fileURLWithPath: tempOBJPath)
                } else {
                    shareURL = scan.writeUSDZ()
                }
            } else if let meshURL = _meshURL {
                shareURL = meshURL
            } else {
                shareURL = scan.writeCompressedPLY()
            }
            
            if let shareURL = shareURL {
                _quickLookOBJURL = shareURL
                // let controller = UIActivityViewController(activityItems: [shareURL], applicationActivities: nil)
                // controller.popoverPresentationController?.sourceView = sender as? UIView
                // present(controller, animated: true, completion: nil)
                let controller = QLPreviewController()
                controller.dataSource = self
                controller.modalPresentationStyle = .overFullScreen
                self.present(controller, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - QLPreviewControllerDataSource
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return _quickLookOBJURL! as QLPreviewItem
    }
    
    @IBAction private func _delete(_ sender: Any) {
        deletionHandler?()
    }
    
    @IBAction private func _done(_ sender: Any) {
        doneHandler?()
    }
    
    @IBAction private func _runMeshing(_ sender: Any) {
        guard let scan = scan else { return }
        
        meshingProgressContainer.isHidden = false
        meshingProgressContainer.alpha = 0
        meshingProgressView.progress = 0
        UIView.animate(withDuration: 0.4) {
            self.meshingProgressContainer.alpha = 1
        }
        
        let meshingParameters = SCMeshingParameters()
        meshingParameters.resolution = 5
        meshingParameters.smoothness = 1
        meshingParameters.surfaceTrimmingAmount = 5
        meshingParameters.closed = true
        
        let textureResolutionPixels = 2048
        
        scan.meshTexturing.reconstructMesh(
            pointCloud: scan.pointCloud,
            textureResolution: textureResolutionPixels,
            meshingParameters: meshingParameters,
            coloringStrategy: .vertex,
            progress: { percentComplete, shouldStop in
                DispatchQueue.main.async {
                    self.meshingProgressView.progress = percentComplete
                }
                
                shouldStop.pointee = ObjCBool(self._shouldCancelMeshing)
            },
            completion: { error, scMesh in
                if let error = error {
                    print("Meshing error: \(error)")
                }
                
                DispatchQueue.main.async {
                    self.meshingProgressContainer.isHidden = true
                    self._shouldCancelMeshing = false
                    
                    if let mesh = scMesh {
                        let node = mesh.buildMeshNode()
                        node.transform = self._pointCloudNode?.transform ?? SCNMatrix4Identity
                        self._pointCloudNode = node
                        self._mesh = mesh
                    }
                }
            }
        )
    }
    
    @IBAction private func cancelMeshing(_ sender: Any) {
        _shouldCancelMeshing = true
    }
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        _initialPointOfView = sceneView.pointOfView!.transform
    }
    
    override func viewWillAppear(_ animated: Bool) {
        sceneView.pointOfView!.transform = _initialPointOfView
        meshButton.isHidden = scan?.plyPath == nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let scan = scan, scan.thumbnail == nil {
            let snapshot = sceneView.snapshot()
            scan.thumbnail = snapshot.resized(toWidth: 640)
        }
    }
    
    // MARK: - Public
    
    var scan: Scan? {
        didSet {
            _pointCloudNode = scan?.pointCloud.buildNode()
        }
    }
    
    var deletionHandler: (() -> Void)?
    var doneHandler: (() -> Void)?
    
    // MARK: - Private
    
    private let _appDelegate = UIApplication.shared.delegate! as! AppDelegate
    private let _shouldExportToOBJ = true
    private var _shouldCancelMeshing = false
    private var _meshURL: URL?
    private var _mesh: SCMesh?
    private var _initialPointOfView = SCNMatrix4Identity
    private var _pointCloudNode: SCNNode? {
        willSet {
            _pointCloudNode?.removeFromParentNode()
        }
        didSet {
            _pointCloudNode?.name = "point cloud"
            
            // Make sure the view is loaded first
            _ = self.view
            
            if let node = _pointCloudNode {
                sceneView.scene!.rootNode.addChildNode(node)
            }
        }
    }
    
}
