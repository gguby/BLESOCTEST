//
//  SocketConnectable.swift
//  BLESOCTEST
//
//  Created by 정원식(Wonsik Jung)/Media Integration팀/SKP on 2022/05/24.
//

import Foundation

protocol SocketConnectable: AnyObject {
    var urlString: String { get set }
    func connect()
    func disconnect()
    func send(msg: String)
}
