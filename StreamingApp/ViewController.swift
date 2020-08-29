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
    
    var webRTCClient = WebRTCClient(iceServers: defaultIceServers)
    var localStream: AnyObject?
    var remoteStream: AnyObject?
    var roomRef: DocumentReference?
    var roomIDRef: DocumentReference?
    var isCaller: Bool?
    @IBOutlet weak var localVideoView: UIView!
    @IBOutlet weak var openCamBtn: UIButton!
    @IBOutlet weak var createRoomBtn: UIButton!
    @IBOutlet weak var joinRoomBtn: UIButton!
    @IBOutlet weak var hangUpBtn: UIButton!
    @IBOutlet weak var roomIdLbl: UILabel!
    
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
        openCamBtn.isEnabled = false
        createRoomBtn.isEnabled = true
        joinRoomBtn.isEnabled = true
        hangUpBtn.isEnabled = true
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
        createRoomBtn.isEnabled = false
        joinRoomBtn.isEnabled = false
        isCaller = true
        
        // TODO: Code for create offer from peerConnection, break it down to type and sdp then push to firestore
        webRTCClient.offer { [weak self] description in
            guard let roomRef = self?.roomRef else { return }
            roomRef.setData(["offer": ["type": "offer", "sdp": description.sdp]]) { [weak self] error in
                if let error = error {
                    print(error)
                    return
                }
                self?.roomIdLbl.isHidden = false
                self?.roomIdLbl.text = "Current room is \(roomRef.documentID) - You are the caller!"
            }
        }
        
        // TODO: Get remote stream from peerConnection and add to remoteStream
        // ??

        // TODO: [callback] Listening for remote session description and add to peerConection
        roomRef?.addSnapshotListener({ (snapshot, error) in
            guard let data = snapshot?.data() else { return }
            guard let answer = data["answer"] as? [String: Any] else { return }
            guard let sdp = answer["sdp"] as? String else { return }
            
            self.webRTCClient.set(remoteSdp: RTCSessionDescription(type: .answer, sdp: sdp)) { error in
                if let error = error {
                    print(error)
                    return
                }
            }
        })

        // TODO: [callback] Listening for remote session description and add to peerConnection
        roomRef?.collection("calleeCandidates").addSnapshotListener({ (snapshot, error) in
            snapshot?.documentChanges.forEach({ (change) in
                if (change.type == .added) {
                    let data = change.document.data()
                    guard let sdp = data["candiate"] as? String, let sdpMLineIndex = data["sdpMLineIndex"] as? Int, let sdpMid = data["sdpMid"] as? String else { return }
                    self.webRTCClient.set(remoteCandidate: RTCIceCandidate(sdp: sdp, sdpMLineIndex: Int32(sdpMLineIndex), sdpMid: sdpMid))
                }
            })
        })
    }
    
    func showAlertGetRoomID(completion: @escaping (String?) -> ()) {
        let alert = UIAlertController(title: "Some Title", message: "Enter a text", preferredStyle: .alert)

        alert.addTextField { (textField) in
            textField.text = "Some default text"
        }

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            completion(textField?.text)
        }))

        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func joinRoom(_ sender: Any) {
        // TODO: disable create room and join room btn
        createRoomBtn.isEnabled = false
        joinRoomBtn.isEnabled = false
        isCaller = false
        
        // TODO: search for room id on firestore, guard if exist
        showAlertGetRoomID { [weak self] roomID in
            self?.roomIDRef = Firestore.firestore().collection("rooms").document(roomID ?? "")
            self?.roomIDRef?.getDocument { (snapshot, error) in
                if error != nil { return }
                
                // TODO: [callback] lissten to remote track and add to remoteStream
                // ??
                
                // TODO: get offer from roomRef above and add to remoteDescription of peerConnection
                guard let data = snapshot?.data() else { return }
                guard let offer = data["offer"] as? [String: Any] else { return }
                guard let sdp = offer["sdp"] as? String else { return }
                
                self?.webRTCClient.set(remoteSdp: RTCSessionDescription(type: .offer, sdp: sdp), completion: { error in
                    if let error = error {
                        print(error)
                        return
                    }
                })

                // TODO: peerConnection create answer and add to local description
                self?.webRTCClient.answer(completion: { [weak self] (description) in
                    // TODO: push that answer to roomRef above
                    self?.roomIDRef?.setData(["answer": ["type": "answer", "sdp": description.sdp]])
                })
                
                // TODO: [callback] listen to roomRef 'callerCandidates' above and add to peerConnection ice candidate
                self?.roomIDRef?.collection("callerCandidates").addSnapshotListener({ (snapshot, error) in
                    if let error = error {
                        print(error)
                        return
                    }
                    snapshot?.documentChanges.forEach({ change in
                        if (change.type == .added) {
                            let data = change.document.data()
                            guard let sdp = data["candidate"] as? String else { return }
                            guard let sdpMLineIndex = data["sdpMLineIndex"] as? Int32 else { return }
                            guard let sdpMid = data["sdpMid"] as? String else { return }
                            self?.webRTCClient.set(remoteCandidate: RTCIceCandidate(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid))
                        }
                    })
                })
            }
        }
    }
    
    @IBAction func hangUp(_ sender: Any) {
        // TODO: stop tracks and close peerConnection
        self.webRTCClient = WebRTCClient(iceServers: defaultIceServers)
        
        // TODO: enable camerabtn, disable the rest
        openCamBtn.isEnabled = true
        createRoomBtn.isEnabled = false
        joinRoomBtn.isEnabled = false
        hangUpBtn.isEnabled = false

        // TODO: delele room on firestore
        if (roomIDRef != nil) {
            roomIDRef?.collection("calleeCandidates").getDocuments(completion: { (snapshot, error) in
                if let error = error {
                    print(error)
                    return
                }
                snapshot?.documents.forEach({ (snapshot) in
                    snapshot.reference.delete()
                })
            })
            roomIDRef?.collection("callerCandidates").getDocuments(completion: { (snapshot, error) in
                if let error = error {
                    print(error)
                    return
                }
                snapshot?.documents.forEach({ (snapshot) in
                    snapshot.reference.delete()
                })
            })
            roomIDRef?.delete()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        openCamBtn.isEnabled = true
        createRoomBtn.isEnabled = false
        joinRoomBtn.isEnabled = false
        hangUpBtn.isEnabled = false
        roomIdLbl.isHidden = true
        
        webRTCClient.delegate = self
        
        roomRef = Firestore.firestore().collection("rooms").document()
    }
}

extension ViewController: WebRTCClientDelegate {
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        guard let roomRef = roomRef, let isCaller = isCaller else { return }
        if isCaller == true {
            let callerCandidatesCollection = roomRef.collection("callerCandidates")
            callerCandidatesCollection.addDocument(data: ["sdpMLineIndex": candidate.sdpMLineIndex, "sdpMid": candidate.sdpMid ?? "", "candidate": candidate.sdp])
        } else {
            guard let roomIDRef = roomIDRef else { return }
            let calleeCandidatesCollection = roomIDRef.collection("calleeCandidates")
            calleeCandidatesCollection.addDocument(data: ["sdpMLineIndex": candidate.sdpMLineIndex, "sdpMid": candidate.sdpMid ?? "", "candidate": candidate.sdp])
        }
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        print("didChangeConnectionState")
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) {
        DispatchQueue.main.async {
            let message = String(data: data, encoding: .utf8) ?? "(Binary: \(data.count) bytes)"
            let alert = UIAlertController(title: "Message from WebRTC", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
}

