//
//  ViewController.swift
//  StreamingApp
//
//  Created by HoangCuong on 8/23/20.
//

import UIKit
import FirebaseFirestore
import AVFoundation
import WebRTC

class ViewController: UIViewController {
    
    let webRTCClient = WebRTCClient(iceServers: defaultIceServers)
    var localStream: AnyObject?
    var remoteStream: AnyObject?
    @IBOutlet weak var localVideoView: UIView!
    @IBOutlet weak var openCamBtn: UIButton!
    @IBOutlet weak var createRoomBtn: UIButton!
    @IBOutlet weak var joinRoomBtn: UIButton!
    @IBOutlet weak var hangUpBtn: UIButton!
    
    @IBAction func openCam(_ sender: Any) {
        // TODO: get local stream and show on small view
        
        #if arch(arm64)
            // Using metal (arm64 only)
            let localRenderer = RTCMTLVideoView(frame: self.localVideoView?.frame ?? CGRect.zero)
            let remoteRenderer = RTCMTLVideoView(frame: self.view.frame)
            localRenderer.videoContentMode = .scaleAspectFill
            remoteRenderer.videoContentMode = .scaleAspectFill
        #else
            // Using OpenGLES for the rest
            let localRenderer = RTCEAGLVideoView(frame: self.localVideoView?.frame ?? CGRect.zero)
            let remoteRenderer = RTCEAGLVideoView(frame: self.view.frame)
        #endif

        self.webRTCClient.startCaptureLocalVideo(renderer: localRenderer)
        self.webRTCClient.renderRemoteVideo(to: remoteRenderer)
        
        if let localVideoView = self.localVideoView {
            self.embedView(localRenderer, into: localVideoView)
        }
        self.embedView(remoteRenderer, into: self.view)
        self.view.sendSubviewToBack(remoteRenderer)
        
        // TODO: disable openCam btn
        
    }
    
    private func embedView(_ view: UIView, into containerView: UIView) {
        containerView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|",
                                                                    options: [],
                                                                    metrics: nil,
                                                                    views: ["view":view]))
        
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|",
                                                                    options: [],
                                                                    metrics: nil,
                                                                    views: ["view":view]))
        containerView.layoutIfNeeded()
    }
    
    @IBAction func createRoom(_ sender: Any) {
        // TODO: disable create room and join room btn
        
        // TODO: Access firestore collection "room"
        
        // TODO: Create PeerConnection with default configuration
        
        // TODO: Get local stream and add to PeerConnection
        
        // TODO: [callback] Code for collecting ICE candidates

        // TODO: Code for create offer from peerConnection, break it down to type and sdp then push to firestore
        
        // TODO: show roomID from firestore
        
        // TODO: Get remote stream from peerConnection and add to remoteStream

        // TODO: [callback] Listening for remote session description and add to peerConection

        // TODO: [callback] Listening for remote session description and add to peerConnection
    }
    
    @IBAction func joinRoom(_ sender: Any) {
        // TODO: search for room id on firestore, guard if exist

        // TODO: create peerConnection with default configuration
        
        // TODO:Get local stream and add to PeerConnection

        // TODO: [callback] collect ICE candidates from peerconnection and push to calleeCandidates of the roomRef above
        
        // TODO: [callback] lissten to remote track and add to remoteStream
        
        // TODO: get offer from roomRef above and add to remoteDescription of peerConnection

        // TODO: peerConnection create answer and add to local description
        // TODO: push that answer to roomRef above
        
        // TODO: [callback] listen to roomRef 'callerCandidates' above and add to peerConnection ice candidate
    }
    
    @IBAction func hangUp(_ sender: Any) {
        // TODO: stop tracks and close peerConnection
        
        // TODO: enable camerabtn, disable the rest

        // TODO: delele room on firestore
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//        let roomRef = Firestore.firestore().collection("rooms")
//        let roomWithOffer = ["offer": 3]
//        roomRef.addDocument(data: roomWithOffer)
    }


}

