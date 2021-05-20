//
//  ViewController.swift
//  Hoang AR Project 2
//
//  Created by Timothy Hoang on 5/20/21.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        sceneView.autoenablesDefaultLighting = true
        
        // Create a new scene
        let scene = SCNScene()
        
        let ballGeometry = SCNSphere(radius: 0.1)
        
        let ballNode = SCNNode(geometry: ballGeometry)
        
        ballNode.position = SCNVector3Make(0, 0, -0.5)
        
        scene.rootNode.addChildNode(ballNode)
        
        // Set the scene to the view
        sceneView.scene = scene
        
        sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:))))
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer){
        let tapLocation = recognizer.location(in: sceneView)
        let estimatedPlane: ARRaycastQuery.Target = .estimatedPlane
        let alignment: ARRaycastQuery.TargetAlignment = .any
        let query: ARRaycastQuery? = sceneView.raycastQuery(from: tapLocation, allowing: estimatedPlane, alignment: alignment)

        if let nonOptQuery: ARRaycastQuery = query {

            let result: [ARRaycastResult] = sceneView.session.raycast(nonOptQuery)

            guard let rayCast: ARRaycastResult = result.first
            else { return }

            self.insertGeometry(rayCast)
        }
    }
    
    func insertGeometry(_ result: ARRaycastResult) {

        let ball = SCNSphere(radius: 0.1)
        let node = SCNNode(geometry: ball)

        // The physicsBody tells SceneKit this geometry should be manipulated by the physics engine
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        node.physicsBody?.mass = 2.0
        node.physicsBody?.categoryBitMask = 1

        // We insert the geometry slightly above the point the user tapped, so that it drops onto the plane
        // using the physics engine
        
        node.position = SCNVector3(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y + 0.5, result.worldTransform.columns.3.z)

        self.sceneView.scene.rootNode.addChildNode(node)
    }
    
    func createPlaneNode(anchor: ARPlaneAnchor) -> SCNNode {
        let plane = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        
        let planeImage = UIImage(named: "art.scnassets/tron_grid.png")
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = planeImage
        planeMaterial.isDoubleSided = true
        
        plane.materials = [planeMaterial]
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        planeNode.physicsBody?.categoryBitMask = 2
        
        return planeNode
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
                
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    

    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let anchorPlane = anchor as? ARPlaneAnchor else { return }
        //print ("new plane anchor found at", anchorPlane.extent)
        let planeNode = createPlaneNode(anchor: anchorPlane)
                
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let anchorPlane = anchor as? ARPlaneAnchor else { return }
        //print ("plane anchor updated to", anchorPlane.extent)
        node.enumerateChildNodes {
            (childNode, _) in
            childNode.removeFromParentNode()
        }
        
        let planeNode = createPlaneNode(anchor: anchorPlane)
        node.addChildNode(planeNode)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
