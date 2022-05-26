//
//  SocketClientViewController.swift
//  BLESOCTEST
//
//  Created by 정원식(Wonsik Jung)/Media Integration팀/SKP on 2022/05/24.
//

import UIKit
import SocketIO

class SocketClientViewController: UIViewController {

    private var textField: UITextField = {
        let textfield = UITextField()
        textfield.placeholder = "message"
        textfield.borderStyle = .roundedRect
        return textfield
    }()

    private let connectButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("소켓연결", for: .normal)
        button.setTitleColor(.black, for: .normal)
        return button
    }()

    private let disconnectButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("소켓종료", for: .normal)
        button.setTitleColor(.black, for: .normal)
        return button
    }()

    private let sendButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("전송", for: .normal)
        button.setTitleColor(.black, for: .normal)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(textField)
        view.addSubview(connectButton)
        view.addSubview(disconnectButton)
        view.addSubview(sendButton)

        connectButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(80)
        }

        disconnectButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(connectButton.snp.bottom).offset(50)
        }

        textField.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.width.equalTo(200)
            $0.height.equalTo(100)
            $0.top.equalTo(disconnectButton.snp.bottom).offset(50)
        }

        sendButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(textField.snp.bottom).offset(50)
        }

        connectButton.addTarget(self, action: #selector(connect(sender:)), for: .touchUpInside)
        disconnectButton.addTarget(self, action: #selector(disconnect(sender:)), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(send(sender:)), for: .touchUpInside)
    }

    @objc func connect(sender: UIButton) {
        SocketIOManager.shared.establishConnection()
    }

    @objc func disconnect(sender: UIButton) {
        SocketIOManager.shared.closeConnection()
    }

    @objc func send(sender: UIButton) {
        for i in 1...10 { 
            SocketIOManager.shared.sendMessage(message: "\(i)")
        }
    }
}
