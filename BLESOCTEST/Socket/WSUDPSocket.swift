//
//  WSUDPSocket.swift
//  BLESOCTEST
//
//  Created by wsjung on 2022/05/26.
//

import Foundation
import Network

class WSUDPSocket: SocketConnectable {
    var urlString: String = "192.168.55.72"
    var connection: NWConnection?


    init() {
        let host: NWEndpoint.Host = NWEndpoint.Host(urlString)
        let port: NWEndpoint.Port = 4445

        connection = NWConnection(host: host, port: port, using: .udp)
    }

    func connect() {
        self.connection?.stateUpdateHandler = { (newState) in
            switch (newState) {
            case .ready:
                print("ready")
            case .setup:
                print("setup")
            case .cancelled:
                print("cancelled")
            case .preparing:
                print("Preparing")
            default:
                print("waiting or failed")

            }
        }
        self.connection?.start(queue: .main)
    }

    func disconnect() {
        self.connection?.cancel()
    }

    func send(msg: String) {
        Log.debug(msg)
        self.connection?.send(content: msg.data(using: .utf8), completion: NWConnection.SendCompletion.contentProcessed({ error in
        }))
    }
}
