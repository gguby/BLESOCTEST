//
//  ViewController.swift
//  BLESOCTEST
//
//  Created by 정원식(Wonsik Jung)/Media Integration팀/SKP on 2022/05/23.
//


import UIKit

class ViewController: UIViewController {

    private let centralButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Central Mode", for: .normal)
        button.setTitleColor(.black, for: .normal)
        return button
    }()

    private let peripheralButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Peripheral Mode", for: .normal)
        button.setTitleColor(.black, for: .normal)
        return button
    }()



    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(centralButton)
        view.addSubview(peripheralButton)

        centralButton.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        peripheralButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(centralButton.snp.bottom).offset(20)
        }

        centralButton.addTarget(self, action: #selector(goCentralView(sender:)), for: .touchUpInside)
        peripheralButton.addTarget(self, action: #selector(goPeriView(sender:)), for: .touchUpInside)
    }

    @objc func goCentralView(sender: UIButton) {
        let vc = CentralViewController()
        self.navigationController?.pushViewController(vc, animated: false)
    }

    @objc func goPeriView(sender: UIButton) {
        let vc = PeripheralViewController()
        self.navigationController?.pushViewController(vc, animated: false)
    }
}

