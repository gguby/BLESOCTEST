//
//  PeripheralViewController.swift
//  BLESOCTEST
//
//  Created by 정원식(Wonsik Jung)/Media Integration팀/SKP on 2022/05/23.
//

import UIKit
import SnapKit

class PeripheralViewController: UIViewController, BLEPeripheralManagerDelegate {
    func didCompleteConnect(manager: BLEPeripheralManager) {
    }

    private let periperalManager = BLEPeripheralManager()

    private let advButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Advertise", for: .normal)
        button.setTitleColor(.black, for: .normal)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white

        view.addSubview(advButton)
        advButton.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        periperalManager.delegate = self
        periperalManager.startBLEPeripheral()
    }

}
