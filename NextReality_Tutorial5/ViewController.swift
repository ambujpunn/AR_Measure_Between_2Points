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

// https://stackoverflow.com/questions/21886224/drawing-a-line-between-two-points-using-scenekit
extension SCNGeometry {
    class func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        
        return SCNGeometry(sources: [source], elements: [element])
    }
}

extension SCNVector3 {
    static func distanceFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> Float {
        let x0 = vector1.x
        let x1 = vector2.x
        let y0 = vector1.y
        let y1 = vector2.y
        let z0 = vector1.z
        let z1 = vector2.z
        
        return sqrtf(powf(x1-x0, 2) + powf(y1-y0, 2) + powf(z1-z0, 2))
    }
}

extension Float {
    func metersToInches() -> Float {
        return self * 39.3701
    }
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var grids = [Grid]()
    
    var numberOfTaps = 0
    
    var startPoint: SCNVector3!
    var endPoint: SCNVector3!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        
        // Create a new scene
        let scene = SCNScene()

        // Set the scene to the view
        sceneView.scene = scene
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        sceneView.addGestureRecognizer(gestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
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
    
    @objc func tapped(gesture: UITapGestureRecognizer) {
        numberOfTaps += 1
        
        // Get 2D position of touch event on screen
        let touchPosition = gesture.location(in: sceneView)
        
        // Translate those 2D points to 3D points using hitTest (existing plane)
        let hitTestResults = sceneView.hitTest(touchPosition, types: .existingPlane)
        
        guard let hitTest = hitTestResults.first else {
            return
        }
        
        // If first tap, add red marker. If second tap, add green marker and reset to 0
        if numberOfTaps == 1 {
            startPoint = SCNVector3(hitTest.worldTransform.columns.3.x, hitTest.worldTransform.columns.3.y, hitTest.worldTransform.columns.3.z)
            addRedMarker(hitTestResult: hitTest)
        }
        else {
            // After 2nd tap, reset taps to 0
            numberOfTaps = 0
            endPoint = SCNVector3(hitTest.worldTransform.columns.3.x, hitTest.worldTransform.columns.3.y, hitTest.worldTransform.columns.3.z)
            addGreenMarker(hitTestResult: hitTest)
            
            addLineBetween(start: startPoint, end: endPoint)
            
            addDistanceText(distance: SCNVector3.distanceFrom(vector: startPoint, toVector: endPoint), at: endPoint)
        }
    }
    
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
   
    func addLineBetween(start: SCNVector3, end: SCNVector3) {
        let lineGeometry = SCNGeometry.lineFrom(vector: start, toVector: end)
        let lineNode = SCNNode(geometry: lineGeometry)
        
        sceneView.scene.rootNode.addChildNode(lineNode)
    }
    
    func addDistanceText(distance: Float, at point: SCNVector3) {
        let textGeometry = SCNText(string: String(format: "%.1f\"", distance.metersToInches()), extrusionDepth: 1)
        textGeometry.font = UIFont.systemFont(ofSize: 10)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.black

        let textNode = SCNNode(geometry: textGeometry)
        textNode.position = SCNVector3Make(point.x, point.y, point.z);
        textNode.scale = SCNVector3Make(0.005, 0.005, 0.005)
        
        sceneView.scene.rootNode.addChildNode(textNode)
    }
}
