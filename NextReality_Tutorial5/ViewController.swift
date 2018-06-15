//
//  ViewController.swift
//  NextReality_Tutorial5
//
//  Created by Ambuj Punn on 6/15/18.
//  Copyright © 2018 Ambuj Punn. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    // 4.2
    var grids = [Grid]()
    
    // 5.3
    var numberOfTaps = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        // 4.4
        sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        
        // Create a new scene
        // 4.1
        let scene = SCNScene()

        // Set the scene to the view
        sceneView.scene = scene
        
        // 5.1
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        sceneView.addGestureRecognizer(gestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // 4.5
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    // 4.3
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        let grid = Grid(anchor: anchor as! ARPlaneAnchor)
        self.grids.append(grid)
        node.addChildNode(grid)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        let grid = self.grids.filter { grid in
            return grid.anchor.identifier == anchor.identifier
            }.first
        
        guard let foundGrid = grid else {
            return
        }
        
        foundGrid.update(anchor: anchor as! ARPlaneAnchor)
    }
    
    // 5.2
    @objc func tapped(gesture: UITapGestureRecognizer) {
        // 5.4
        numberOfTaps += 1
        
        // Get 2D position of touch event on screen
        let touchPosition = gesture.location(in: sceneView)
        
        // Translate those 2D points to 3D points using hitTest (existing plane)
        let hitTestResults = sceneView.hitTest(touchPosition, types: .existingPlane)
        
        guard let hitTest = hitTestResults.first else {
            return
        }
        
        // 5.5
        // If first tap, add red marker. If second tap, add green marker and reset to 0
        if numberOfTaps == 1 {
            addRedMarker(hitTestResult: hitTest)
        }
        else {
            // After 2nd tap, reset taps to 0
            numberOfTaps = 0
            addGreenMarker(hitTestResult: hitTest)
        }
    }
    
    // 5.6
    func addRedMarker(hitTestResult: ARHitTestResult) {
        addMarker(hitTestResult: hitTestResult, color: .red)
    }
    
    func addGreenMarker(hitTestResult: ARHitTestResult) {
        addMarker(hitTestResult: hitTestResult, color: .green)
    }
    
    func addMarker(hitTestResult: ARHitTestResult, color: UIColor) {
        let geometry = SCNSphere(radius: 0.01)
        geometry.firstMaterial?.diffuse.contents = color
        
        let markerNode = SCNNode(geometry: geometry)
        markerNode.position = SCNVector3(hitTestResult.worldTransform.columns.3.x, hitTestResult.worldTransform.columns.3.y, hitTestResult.worldTransform.columns.3.z)
        
        sceneView.scene.rootNode.addChildNode(markerNode)
    }
    
}
