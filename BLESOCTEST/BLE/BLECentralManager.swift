//
//  BLEProvider.swift
//  BluetoothGamepad
//
//  Created by wsjung on 2021/10/28.
//

import CoreBluetooth
import UIKit

struct BLEConst {
    static let uuidService = CBUUID(string: "25AE1441-05D3-4C5B-8281-93D4E07420CF")
    static let uuidCharForRead = CBUUID(string: "25AE1442-05D3-4C5B-8281-93D4E07420CF")
    static let uuidCharForWrite = CBUUID(string: "25AE1443-05D3-4C5B-8281-93D4E07420CF")
    static let uuidCharForIndicate = CBUUID(string: "25AE1444-05D3-4C5B-8281-93D4E07420CF")
}

class BLECentralManager: NSObject {

    static let shared = BLECentralManager()

    enum BLELifecycleState: String {
        case bluetoothNotReady
        case disconnected
        case scanning
        case connecting
        case connectedDiscovering
        case connected

        var isShowMsg: Bool {
            switch self {
            case .bluetoothNotReady, .connectedDiscovering, .scanning:
                return false
            case .disconnected, .connecting, .connected:
                return true
            }
        }

        var msg: String {
            switch self {
            case .bluetoothNotReady, .connectedDiscovering, .scanning:
                return ""
            case .disconnected:
                return "연결종료"
            case .connected:
                return "연결"
            case .connecting:
                return "연결중"
            }
        }
    }

    var bleCentral: CBCentralManager!
    var connectedPeripheral: CBPeripheral?
    var scannedPeripherals: [CBPeripheral] = []

    var userWantsToScanAndConnect: Bool {
        return lifecycleState != .connected
    }

    var lifecycleState = BLELifecycleState.bluetoothNotReady {
        didSet {
            guard lifecycleState != oldValue else { return }
            print("state = \(lifecycleState)")
        }
    }

    override init() {
        super.init()
    }

    func initBLE() {
        // using DispatchQueue.main means we can update UI directly from delegate methods
        bleCentral = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }

    private func bleRestartLifecycle() {
        guard bleCentral.state == .poweredOn else {
            connectedPeripheral = nil
            lifecycleState = .bluetoothNotReady
            return
        }

        if userWantsToScanAndConnect {
            if let oldPeripheral = connectedPeripheral {
                bleCentral.cancelPeripheralConnection(oldPeripheral)
            }
            bleScan()
        } else {
            bleDisconnect()
        }
    }

    func bleScan() {
        lifecycleState = .scanning
        bleCentral.scanForPeripherals(withServices: [BLEConst.uuidService], options: nil)
    }

    func bleConnect(to peripheral: CBPeripheral) {
        bleCentral.stopScan()
        connectedPeripheral = peripheral
        lifecycleState = .connecting
        bleCentral.connect(peripheral, options: nil)
    }

    func bleDisconnect() {
        if bleCentral.isScanning {
            bleCentral.stopScan()
        }
        if let peripheral = connectedPeripheral {
            bleCentral.cancelPeripheralConnection(peripheral)
        }
        lifecycleState = .disconnected
        scannedPeripherals.removeAll()
        connectedPeripheral = nil
    }

    func bleReadCharacteristic(uuid: CBUUID) {
        guard let characteristic = getCharacteristic(uuid: uuid) else {
            print("ERROR: read failed, characteristic unavailable, uuid = \(uuid.uuidString)")
            return
        }
        connectedPeripheral?.readValue(for: characteristic)
    }

    func write(str: String) {
        guard let data = str.data(using: .utf8) else { return }
        bleWriteCharacteristic(data: data)
    }

    func bleWriteCharacteristic(_ uuid: CBUUID = BLEConst.uuidCharForWrite, data: Data) {
        let uuid = BLEConst.uuidCharForWrite

        guard let characteristic = getCharacteristic(uuid: uuid) else {
            print("ERROR: write failed, characteristic unavailable, uuid = \(uuid.uuidString)")
            return
        }
        connectedPeripheral?.writeValue(data, for: characteristic, type: .withResponse)
    }

    func getCharacteristic(uuid: CBUUID) -> CBCharacteristic? {
        let uuidService = BLEConst.uuidService

        guard let service = connectedPeripheral?.services?.first(where: { $0.uuid == uuidService }) else {
            return nil
        }
        return service.characteristics?.first { $0.uuid == uuid }
    }

    private func bleGetStatusString() -> String {
        guard let bleCentral = bleCentral else { return "not initialized" }
        switch bleCentral.state {
        case .unauthorized:
            return bleCentral.state.stringValue + " (allow in Settings)"
        case .poweredOff:
            return "Bluetooth OFF"
        case .poweredOn:
            return "ON, \(lifecycleState)"
        default:
            return bleCentral.state.stringValue
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BLECentralManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("central didUpdateState: \(central.state.stringValue)")
        bleRestartLifecycle()
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name else { return }
        if scannedPeripherals.contains(where: { $0.name == name }) == false {
            print("didDiscover {name = \(name)}")
            scannedPeripherals.append(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("didConnect")
        connectedPeripheral = peripheral
        lifecycleState = .connectedDiscovering
        peripheral.delegate = self
        let uuidService = BLEConst.uuidService
        peripheral.discoverServices([uuidService])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if peripheral === connectedPeripheral {
            print("didFailToConnect")
            connectedPeripheral = nil
            bleRestartLifecycle()
        } else {
            print("didFailToConnect, unknown peripheral, ingoring")
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral === connectedPeripheral {
            print("didDisconnect")
            connectedPeripheral = nil
            bleRestartLifecycle()
        } else {
            print("didDisconnect, unknown peripheral, ingoring")
        }
    }
}

extension BLECentralManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let uuidService = BLEConst.uuidService

        guard let service = peripheral.services?.first(where: { $0.uuid == uuidService }) else {
            print("ERROR: didDiscoverServices, service NOT found\nerror = \(String(describing: error)), disconnecting")
            bleCentral.cancelPeripheralConnection(peripheral)
            return
        }

        print("didDiscoverServices, service found")
        peripheral.discoverCharacteristics([BLEConst.uuidCharForRead,
                                            BLEConst.uuidCharForWrite,
                                            BLEConst.uuidCharForIndicate], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("didModifyServices")
        // usually this method is called when Android application is terminated
        let uuidService = BLEConst.uuidService

        if invalidatedServices.first(where: { $0.uuid == uuidService }) != nil {
            print("disconnecting because peripheral removed the required service")
            bleCentral.cancelPeripheralConnection(peripheral)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        print("didDiscoverCharacteristics \(error == nil ? "OK" : "error: \(String(describing: error))")")

        for characteristic in characteristics {
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("didUpdateValue error: \(String(describing: error))")
            return
        }

        let data = characteristic.value ?? Data()
        let dataString = String(data: data, encoding: .utf8)
        print("didUpdateValue: \(String(describing: dataString))")
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        print("didWrite \(error == nil ? "OK" : "error: \(String(describing: error))")")
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard error == nil else {
            print("didUpdateNotificationState error\n\(String(describing: error))")
            lifecycleState = .connected
            return
        }

        if characteristic.isNotifying {
            peripheral.readValue(for: characteristic)
        }
    }
}

extension CBManagerState {
    var stringValue: String {
        switch self {
            case .unknown: return "unknown"
            case .resetting: return "resetting"
            case .unsupported: return "unsupported"
            case .unauthorized: return "unauthorized"
            case .poweredOff: return "poweredOff"
            case .poweredOn: return "poweredOn"
            @unknown default: return "\(rawValue)"
        }
    }
}
