//
//  SocketIOManager.swift
//  BLESOCTEST
//
//  Created by 정원식(Wonsik Jung)/Media Integration팀/SKP on 2022/05/24.
//

import Foundation
import SocketIO

class SocketIOManager: NSObject {
    static let shared = SocketIOManager()
    private var manager = SocketManager(socketURL: URL(string: "http://10.202.213.236:3000")!,
                                        config: [.log(true),
                                                 .compress,
                                                 .forceWebsockets(true)])
    private var socket: SocketIOClient!

    override init() {
        super.init()
        socket = self.manager.defaultSocket
        socket.on("test") { dataArray, ack in
            print(dataArray)
        }

        socket.on(clientEvent: .connect) {data, ack in
            print("socket connected")
        }

        self.socket.on(clientEvent: .error) {data, ack in
            print("error")
        }

        self.socket?.on(clientEvent: .disconnect){data, ack in
            print("disconnect")
        }
    }

    func establishConnection() {
        socket.connect()
    }

    func closeConnection() {
        socket.disconnect()
    }

    func sendMessage(message: String) {
        socket.emit("chat message", message)
    }
}
