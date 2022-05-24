//
//  CentralViewController.swift
//  BLESOCTEST
//
//  Created by 정원식(Wonsik Jung)/Media Integration팀/SKP on 2022/05/23.
//

import Foundation
import UIKit

class CentralViewController: UIViewController {

    private let bleCentral = BLECentralManager()

    private let connectButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Connect", for: .normal)
        button.setTitleColor(.black, for: .normal)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white

        view.addSubview(connectButton)
        connectButton.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        bleCentral.initBLE()
    }

    @objc func connect(sender: UIButton) {
        bleCentral.bleScan()
    }
}
