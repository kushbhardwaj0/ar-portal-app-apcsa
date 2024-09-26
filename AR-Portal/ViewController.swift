//
//ViewController.swift
//AR-Portal
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    //prevent dupe portals
    var portalDisplayed: Bool = false
    //has a floor been found
    var planeDetectedForGood = false
    //vars
    var roof: String = ""
    var floor: String = ""
    var backWall: String = ""
    var sideWallA: String = ""
    var sideWallB: String = ""
    var sideDoorA: String = ""
    var sideDoorB: String = ""

    var createNewPortal: Bool = false


    //linking from the storyboard
    @IBOutlet weak var planeDetected: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var earth: UIButton!
    @IBOutlet weak var moon: UIButton!
    @IBOutlet weak var mars: UIButton!


    //ar configuration
    let configuration = ARWorldTrackingConfiguration()
    //viewdidload - basically the main method, runs when the app starts
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        self.sceneView.delegate = self
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }



    //if the mars button is pressed
    @IBAction func mars(_ sender: Any) {
        prepareForNewPortal()
        setPortalAssets(for: "Mars")
    }
    //if moon
    @IBAction func moon(_ sender: Any) {
        prepareForNewPortal()
        setPortalAssets(for: "Moon")
    }
    //if earth
    @IBAction func earth(_ sender: Any) {
        prepareForNewPortal()
        setPortalAssets(for: "Earth")
    }
    
    //prep for new portal
    private func prepareForNewPortal() {
        self.createNewPortal = true
        self.portalDisplayed = false
    }
    //keeping the asset assignments in one place to make it easier
    private func setPortalAssets(for environment: String) {
        switch environment {
        case "Mars":
            self.roof = "p_U"
            self.floor = "n_D"
            self.backWall = "p_R"
            self.sideWallA = "p_F"
            self.sideWallB = "n_L"
            self.sideDoorA = "sideMarsA"
            self.sideDoorB = "sideMarsB"
        case "Moon":
            self.roof = "church-roof"
            self.floor = "church-floor"
            self.backWall = "church-front"
            self.sideWallA = "church-right"
            self.sideWallB = "church-left"
            self.sideDoorA = "church-left-door"
            self.sideDoorB = "church-right-door"
        case "Earth":
            self.roof = "ggroof"
            self.floor = "ggfloor"
            self.backWall = "ggbackwall"
            self.sideWallA = "ggrightwall"
            self.sideWallB = "ggleftwall"
            self.sideDoorA = "ggrightdoor"
            self.sideDoorB = "ggleftdoor"
        //if something goes wrong quit
        default:
            break
        }
    }
    
    //if the screen is tapped
    @objc func handleTap(sender: UITapGestureRecognizer){
        guard let sceneView = sender.view as? ARSCNView, let touchLocation = sender.location(in: sceneView) as? CGPoint else { return }
        let hitTestResults = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
        
        //if its tapped on a valid plane
        if let hitTestResult = hitTestResults.first {
            //remove any existing portal
            if self.createNewPortal {
                self.sceneView.scene.rootNode.childNode(withName: "Portal", recursively: false)?.removeFromParentNode()
                self.createNewPortal = false
            }
            
            //new portal if one is not currently displayed
            if !self.portalDisplayed {
                self.addPortal(hitTestResult: hitTestResult)
            }
        } else {
            self.planeDetected.text = "No plane detected here. Try another spot."
            self.planeDetected.isHidden = false
        }
    }
    
    //add the portal to the scene at the detected plane
    func addPortal(hitTestResult: ARHitTestResult) {
        guard let portalScene = SCNScene(named: "Portal.scnassets/Portal.scn"),
              let portalNode = portalScene.rootNode.childNode(withName: "Portal", recursively: false) else {
            return
        }
        
        let transform = hitTestResult.worldTransform
        portalNode.position = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        //if the roof is empty that means the user has not selected a location yet
        if roof.isEmpty {
            self.planeDetected.text = "Please select a location first"
            self.planeDetected.isHidden = false
        } else {
            //adding the walls roofs and floors
            self.sceneView.scene.rootNode.addChildNode(portalNode)
            addPlane(nodeName: "roof", portalNode: portalNode, imageName: roof)
            addPlane(nodeName: "floor", portalNode: portalNode, imageName: floor)
            addWalls(nodeName: "backWall", portalNode: portalNode, imageName: backWall)
            addWalls(nodeName: "sideWallA", portalNode: portalNode, imageName: sideWallA)
            addWalls(nodeName: "sideWallB", portalNode: portalNode, imageName: sideWallB)
            addWalls(nodeName: "sideDoorA", portalNode: portalNode, imageName: sideDoorA)
            addWalls(nodeName: "sideDoorB", portalNode: portalNode, imageName: sideDoorB)
            //displaying the portal
            self.portalDisplayed = true
        }
    }
    
    //ARKit renderer function for tracking plane detection
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else { return }
        
        DispatchQueue.main.async {
            if !self.planeDetectedForGood {
                self.planeDetected.isHidden = false
                self.planeDetected.text = "Now tap the floor for the portal to appear!"
                self.planeDetectedForGood = true
            }
        }
        //remove "tap floor" text after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.planeDetected.isHidden = true
        }
    }
    
    //add walls to the portal
    func addWalls(nodeName: String, portalNode: SCNNode, imageName: String) {
        guard let child = portalNode.childNode(withName: nodeName, recursively: true) else { return }
        child.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "Portal.scnassets/\(imageName).png")
        child.renderingOrder = 200
        if let mask = child.childNode(withName: "mask", recursively: false) {
            //make the original wall completely transparent
            //so you can see the overlaid image
            mask.geometry?.firstMaterial?.transparency = 0.0000000000000000000001
        }
    }
    
    //add planes to the portal
    func addPlane(nodeName: String, portalNode: SCNNode, imageName: String) {
        guard let child = portalNode.childNode(withName: nodeName, recursively: true) else { return }
        child.renderingOrder = 200
        child.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "Portal.scnassets/\(imageName).png")
    }
}
