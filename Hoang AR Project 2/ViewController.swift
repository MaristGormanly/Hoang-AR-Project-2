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
    
    var cubes = [SCNNode()]

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
        
        /*let ballGeometry = SCNSphere(radius: 0.1)
        
        let ballNode = SCNNode(geometry: ballGeometry)
        
        ballNode.position = SCNVector3Make(0, 0, -0.5)
        
        scene.rootNode.addChildNode(ballNode)*/
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Gesture recognizers for the tap to place and the hold for force
        sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:))))
        sceneView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleHold(recognizer:))))
    }
    
    // Tap action
    @objc func handleTap(recognizer: UITapGestureRecognizer){
        // Selects spot on device then translates 2d to 3d space
        let tapLocation = recognizer.location(in: sceneView)
        let estimatedPlane: ARRaycastQuery.Target = .estimatedPlane
        let alignment: ARRaycastQuery.TargetAlignment = .any
        let query: ARRaycastQuery? = sceneView.raycastQuery(from: tapLocation, allowing: estimatedPlane, alignment: alignment)

        if let nonOptQuery: ARRaycastQuery = query {

            let result: [ARRaycastResult] = sceneView.session.raycast(nonOptQuery)

            guard let rayCast: ARRaycastResult = result.first
            else { return }

            // Inserts geometry
            self.insertGeometry(rayCast)
        }
    }
    
    // Hold action
    @objc func handleHold(recognizer: UILongPressGestureRecognizer){
        // Selects spot on device then translates 2d to 3d space
        let tapLocation = recognizer.location(in: sceneView)
        let estimatedPlane: ARRaycastQuery.Target = .estimatedPlane
        let alignment: ARRaycastQuery.TargetAlignment = .any
        let query: ARRaycastQuery? = sceneView.raycastQuery(from: tapLocation, allowing: estimatedPlane, alignment: alignment)

        if let nonOptQuery: ARRaycastQuery = query {

            let result: [ARRaycastResult] = sceneView.session.raycast(nonOptQuery)

            guard let rayCast: ARRaycastResult = result.first
            else { return }

            //Causes outwards force from hold spot
            self.explode(rayCast)
        }
    }
    
    func explode(_ result: ARRaycastResult){
        let position = SCNVector3(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y - 0.1, result.worldTransform.columns.3.z)
        
        //Find all cubes within the area
        for cubeNode in cubes {
            // The distance between the explosion and the geometry
            var distancex = cubeNode.worldPosition.x - position.x
            var distancey = cubeNode.worldPosition.y - position.y
            var distancez = cubeNode.worldPosition.z - position.z

            let len = (distancex * distancex + distancey * distancey + distancez * distancez)

            let maxDistance = 2
            var scale = max(0, (Int(maxDistance) - Int(len)))

            // Scale the force of the explosion
            scale = scale * scale * 2
            
            distancex = distancex / len * Float(scale)
            distancey = distancey / len * Float(scale)
            distancez = distancez / len * Float(scale)
            
            let forceArea = SCNVector3(distancex, distancey, distancez)
            
            cubeNode.physicsBody?.applyForce(forceArea, asImpulse: true)
        }
        
    }
    
    func insertGeometry(_ result: ARRaycastResult) {

        //let ball = SCNSphere(radius: 0.1)
        //let node = SCNNode(geometry: ball)

        let cube = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        let node = SCNNode(geometry: cube)
        
        // Add physics to the object
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        node.physicsBody?.mass = 2.0
        node.physicsBody?.categoryBitMask = 1

        // Insert the geometry slightly above the point the user tapped
        
        node.position = SCNVector3(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y + 0.5, result.worldTransform.columns.3.z)

        // Add the cube to our array to be located later
        cubes.append(node)
        
        self.sceneView.scene.rootNode.addChildNode(node)
    }
    
    func createPlaneNode(anchor: ARPlaneAnchor) -> SCNNode {
        
        // The plane needs to be a box or else the physics make it so objects on top jitter
        let planeHeight = 0.01;
        let plane = SCNBox(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z), length: CGFloat(planeHeight), chamferRadius: 0)
        
        //image for visualization
        let planeImage = UIImage(named: "art.scnassets/tron_grid.png")
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = planeImage
        planeMaterial.isDoubleSided = true
        
        plane.materials = [planeMaterial]
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        
        // Give the plane some physics so it doesnt move but can interact with other objects
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        planeNode.physicsBody?.categoryBitMask = 2
        
        return planeNode
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // For debugging
        //self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
                
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
    

    // Located and adds nodes for the plane anchor when establishing new planes in the area
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let anchorPlane = anchor as? ARPlaneAnchor else { return }
        //print ("new plane anchor found at", anchorPlane.extent)
        let planeNode = createPlaneNode(anchor: anchorPlane)
                
        node.addChildNode(planeNode)
    }
    
    //updates the planes when they shift
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
