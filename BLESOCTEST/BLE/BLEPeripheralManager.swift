//
//  BLEPeripheralManager.swift
//  BluetoothGamepad
//
//  Created by 정원식(Wonsik Jung)/Media Integration팀/SKP on 2021/12/08.
//

import Foundation
import CoreBluetooth

protocol BLEPeripheralManagerDelegate {
    func didCompleteConnect(manager: BLEPeripheralManager)
}

class BLEPeripheralManager : NSObject {

    struct BLEPeriphralConstants {
        static let peripheralName    = "Peripheral Service"
        static let ATVV_SERVICE_UUID = "AB5E0001-5A21-4F05-BC7D-AF01F617B664"
        static let ATVV_CHAR_TX      = "AB5E0002-5A21-4F05-BC7D-AF01F617B664"
        static let ATVV_CHAR_AUDIO   = "AB5E0003-5A21-4F05-BC7D-AF01F617B664"
        static let ATVV_CHAR_CTL     = "AB5E0004-5A21-4F05-BC7D-AF01F617B664"
    }

    static let shared: BLEPeripheralManager = BLEPeripheralManager()

    private var blePeripheral: CBPeripheralManager! = nil
    private var createdService = [CBService]()

    private var notifyCharacteristic: CBMutableCharacteristic?
    private var notifyCentral: CBCentral? = nil

    private var audioCharacteristic: CBMutableCharacteristic?
    private var audioCentral: CBCentral? = nil

    private var queue = Queue<Data>()
    private let semaphore = DispatchSemaphore(value: 1)

    private var sendEncodeData: Queue<Data> = Queue()

    var delegate: BLEPeripheralManagerDelegate?

    func startBLEPeripheral() {

        Log.debug("startBLEPeripheral")
        Log.debug("Discoverable name : " + BLEPeriphralConstants.peripheralName)

        // start the Bluetooth periphal manager
//        let options: Dictionary = [CBPeripheralManagerOptionRestoreIdentifierKey: "myId"]
        blePeripheral = CBPeripheralManager(delegate: self, queue: nil, options: nil)
    }

    // Stop advertising.
    //
    func stopBLEPeripheral() {
        self.blePeripheral.removeAllServices()
        self.blePeripheral.stopAdvertising()
    }

    func createServices() {
        Log.debug("createServices")

        // service
        let service = CBMutableService(type: BLEConst.uuidService, primary: true)

        // characteristic
        var chs = [CBMutableCharacteristic]()

        chs.append(CBMutableCharacteristic(type: BLEConst.uuidCharForWrite,
                                           properties: [.write],
                                           value: nil,
                                           permissions: [.writeable]))

        // Create the service, add the characteristic to it
        service.characteristics = chs

        createdService.append(service)
        blePeripheral.add(service)
    }

    private func showArray(array: [UInt8]) {
        var str = ""
        for v in array {
            str += String(format:"0x%02X ", v)
        }
        Log.debug("Show " + str)
    }

    private func reseveAddQueue(data: Data) {
        semaphore.wait()
        queue.enqueue(data)
        semaphore.signal()
    }

    private func sendData(data: Data) {
        guard let audioCharacteristic = audioCharacteristic else {
            return
        }

        semaphore.wait()
        if !blePeripheral.updateValue(data, for: audioCharacteristic, onSubscribedCentrals: []) {
            semaphore.signal()
            reseveAddQueue(data: data)
        } else {
            Log.debug("success send audio data")
            semaphore.signal()
            send()
        }
    }

    func send() {
        guard let notifyCharacteristic = notifyCharacteristic else {
            return
        }

        guard let encodedData = sendEncodeData.dequeue() else {
            return
        }

        semaphore.wait()
        if !blePeripheral.updateValue(encodedData, for: notifyCharacteristic, onSubscribedCentrals: []) {
            semaphore.signal()
            reseveAddQueue(data: encodedData)
        } else {
            Log.debug("Success audio sync")
        }
        semaphore.signal()
    }
}

extension BLEPeripheralManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager)
    {
        Log.debug("peripheralManagerDidUpdateState")

        if peripheral.state == .poweredOn {
            self.createServices()
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?){
        Log.debug("peripheralManager didAdd service")

        if error != nil {
            Log.debug("Error adding services: \(error!.localizedDescription)")
        }
        else {
            Log.debug("service:\n" + service.uuid.uuidString)

            // Create an advertisement, using the service UUID
            let advertisement: [String : Any] = [CBAdvertisementDataServiceUUIDsKey : [service.uuid],
                                                    CBAdvertisementDataLocalNameKey : BLEPeriphralConstants.peripheralName]
            //28 bytes maxu !!!
            // only 10 bytes for the name
            // https://developer.apple.com/reference/corebluetooth/cbperipheralmanager/1393252-startadvertising

            // start the advertisement
            Log.debug( "Advertisement datas: " + String(describing: advertisement))
            self.blePeripheral.startAdvertising(advertisement)
            Log.debug("Starting to advertise.")
        }
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?){
        if error != nil {
            Log.error(("peripheralManagerDidStartAdvertising Error :\n \(error!.localizedDescription)"))
        }
        else {
            Log.debug("peripheralManagerDidStartAdvertising OK")
        }
    }

    // Central request to be notified to a charac.
    //
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        Log.debug("peripheralManager didSubscribeTo characteristic :\n" + characteristic.uuid.uuidString)

        if characteristic.uuid.uuidString == BLEPeriphralConstants.ATVV_CHAR_CTL {
            self.notifyCharacteristic = characteristic as? CBMutableCharacteristic
            self.notifyCentral = central
            Log.debug("central.maximumUpdateValueLength == ", central.maximumUpdateValueLength)
        } else if characteristic.uuid.uuidString == BLEPeriphralConstants.ATVV_CHAR_AUDIO {
            self.audioCharacteristic = characteristic as? CBMutableCharacteristic
            self.audioCentral = central
            Log.debug("central.maximumUpdateValueLength == ", central.maximumUpdateValueLength)
        }
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        guard queue.isEmpty == false else { return }
        if let data = queue.dequeue() {
            semaphore.wait()
            Log.debug("peripheralManagerIsReady data count:", data.count)
            if peripheral.updateValue(data, for: audioCharacteristic!, onSubscribedCentrals: []) {
                semaphore.signal()
                send()
            }
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {

        Log.debug("peripheralManager didReceiveRead\n" + "request uuid: " + request.characteristic.uuid.uuidString)

        // prepare advertisement data
        request.value = request.characteristic.value

        // Respond to the request
        blePeripheral.respond( to: request, withResult: .success)

        // acknowledge : ok
        peripheral.respond(to: request, withResult: CBATTError.success)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        guard let request = requests.first else { return }
        Log.debug("peripheralManager didReceiveWrite")
        Log.debug("request uuid: " + request.characteristic.uuid.uuidString)

        var str = ""
        if let data = request.value {
            let recieveArray = data.toArray(type: UInt8.self)
            for v in recieveArray {
                str += String(format:"0x%02X ", v)
            }
            Log.debug("value sent by central Manager :\n", str)
//            let array = parseCMD(array: recieveArray)
//            request.value = array.data
//            peripheral.respond(to: request, withResult: .success)
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
    }

    func respond(to request: CBATTRequest, withResult result: CBATTError.Code) {
        Log.debug("respnse requested")
    }

    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        Log.debug("peripheral name changed")
    }

    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        Log.debug("peripheral service modified")
    }
}

extension Array where Element == UInt8 {
    var data: Data {
        return Data(self)
    }
}

extension Data {
    init<T>(fromArray values: [T]) {
        self = values.withUnsafeBytes { Data($0) }
    }

    func toArray<T>(type: T.Type) -> [T] where T: ExpressibleByIntegerLiteral {
        var array = Array<T>(repeating: 0, count: self.count/MemoryLayout<T>.stride)
        _ = array.withUnsafeMutableBytes { copyBytes(to: $0) }
        return array
    }
}
