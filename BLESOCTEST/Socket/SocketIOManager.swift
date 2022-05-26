//
//  SocketIOManager.swift
//  BLESOCTEST
//
//  Created by 정원식(Wonsik Jung)/Media Integration팀/SKP on 2022/05/24.
//

import Foundation

class SocketIOManager: NSObject {

    enum SocketType {
        case web
        case io
        case udp
    }

    static let shared = SocketIOManager()

    private var socketType: SocketType = .udp
    private var socket: SocketConnectable!

    override init() {
        super.init()

        switch socketType {
        case .web:
            socket = WSWebSocket()
        case .io:
            socket = WSHttpSocket()
        case .udp:
            socket = WSUDPSocket()
        }
    }

    func establishConnection() {
        socket.connect()
    }

    func closeConnection() {
        socket.disconnect()
    }

    func sendMessage(message: String) {
        socket.send(msg: message)
    }
}
