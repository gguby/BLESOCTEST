//
//  WSWebSocket.swift
//  BLESOCTEST
//
//  Created by 정원식(Wonsik Jung)/Media Integration팀/SKP on 2022/05/24.
//

import Foundation
import Starscream

class WSWebSocket: SocketConnectable, WebSocketDelegate {

    var urlString: String = "ws://10.202.213.236:8001/"

    private var webSocket: WebSocket?
    
    init() {
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        webSocket = WebSocket(request: request)
        webSocket?.delegate = self
    }

    func connect() {
        webSocket?.connect()
    }

    func disconnect() {
        webSocket?.disconnect()
    }

    func send(msg: String) {
        webSocket?.write(string: msg)
    }

    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
            case .connected(let headers):
              client.write(string: "userName")
              print("websocket is connected: \(headers)")
            case .disconnected(let reason, let code):
              print("websocket is disconnected: \(reason) with code: \(code)")
            case .text(let text):
              print("received text: \(text)")
            case .binary(let data):
              print("Received data: \(data.count)")
            case .ping(_):
              break
            case .pong(_):
              break
            case .viabilityChanged(_):
              break
            case .reconnectSuggested(_):
              break
            case .cancelled:
              print("websocket is canclled")
            case .error(let error):
              print("websocket is error = \(error!)")
            }
    }
}
