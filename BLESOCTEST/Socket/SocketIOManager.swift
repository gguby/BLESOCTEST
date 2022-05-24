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
    }

    static let shared = SocketIOManager()

    private var socketType: SocketType = .web
    private var socket: SocketConnectable!

    override init() {
        super.init()

        if socketType == .io {
            socket = WSHttpSocket()
        } else {
            socket = WSWebSocket()
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
