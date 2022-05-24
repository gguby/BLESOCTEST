//
//  WSHttpSocket.swift
//  BLESOCTEST
//
//  Created by 정원식(Wonsik Jung)/Media Integration팀/SKP on 2022/05/24.
//

import SocketIO

class WSHttpSocket: SocketConnectable {
    var urlString: String = "http://10.202.213.236:3000"

    private var manager: SocketManager!
    private var socket: SocketIOClient!

    init() {
        self.manager = SocketManager(socketURL: URL(string: urlString)!,
                                     config: [.log(true),
                                              .compress,
                                              .forceWebsockets(true)])

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

    func connect() {
        socket.connect()
    }

    func disconnect() {
        socket.disconnect()
    }

    func send(msg: String) {
        socket.emit("chat message", msg)
    }
}
