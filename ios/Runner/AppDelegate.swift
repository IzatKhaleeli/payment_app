import UIKit
import Flutter
import CoreBluetooth

@UIApplicationMain
class AppDelegate: FlutterAppDelegate, CBCentralManagerDelegate, CBPeripheralDelegate {

    var centralManager: CBCentralManager?
    var discoveredPeripherals: [CBPeripheral] = []
    var connectedPeripheral: CBPeripheral?
    var flutterResult: FlutterResult?
    var eventSink: FlutterEventSink?
    var scanningTimer: Timer?
    var printCharacteristic: CBCharacteristic?  // Characteristic used to write print commands

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Initialize the Bluetooth central manager
        centralManager = CBCentralManager(delegate: self, queue: nil)

        // Setup Flutter method channel
        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "bluetooth_channel", binaryMessenger: controller.binaryMessenger)
        let eventChannel = FlutterEventChannel(name: "bluetooth_scan_events", binaryMessenger: controller.binaryMessenger)
        eventChannel.setStreamHandler(self) // Set stream handler for event channel

        // Handle Flutter method calls
        channel.setMethodCallHandler { (call, result) in
            switch call.method {
            case "startScan":
                self.flutterResult = result
                self.startScanning()
            case "stopScan":
                self.stopScanning(result: result)
            case "connectToDevice":
                if let arguments = call.arguments as? [String: Any],
                   let deviceAddress = arguments["address"] as? String {
                    self.connectToDevice(address: deviceAddress, result: result)
                }
            case "disconnectDevice":
                self.disconnectFromDevice(result: result)
            case "printImageBytes":
                print("case print image")
                if let arguments = call.arguments as? [String: Any],
                   let imageBytes = arguments["bytes"] as? FlutterStandardTypedData {
                    print("Successfully received imageBytes with size: \(imageBytes.data.count) bytes")
                    self.printImageBytes(result: result, bytes: imageBytes)
                } else {
                    print("Failed to retrieve imageBytes from arguments")
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Could not retrieve bytes", details: nil))
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - Start Scanning
private func startScanning() {
    discoveredPeripherals = []
    guard let centralManager = centralManager, centralManager.state == .poweredOn else {
        flutterResult?(FlutterError(code: "BLUETOOTH_OFF", message: "Bluetooth is not powered on", details: nil))
        return
    }

    // Start scanning for peripherals
    centralManager.scanForPeripherals(withServices: nil, options: nil)
    print("Scanning for devices...")

    // Set a timer to stop scanning after 3 seconds
    scanningTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(stopScanningTimer), userInfo: nil, repeats: false)
}

// MARK: - Stop Scanning Timer
    @objc private func stopScanningTimer() {
        // Stop the scan
        guard let centralManager = centralManager else {
            return
        }
        centralManager.stopScan()
        print("Stopped scanning.")

        // Invalidate the timer after use
        scanningTimer?.invalidate()
        scanningTimer = nil

        // Notify Flutter that the scan has been stopped
        flutterResult?(true)
    }

    // MARK: - Stop Scanning
    private func stopScanning(result: @escaping FlutterResult) {
        guard let centralManager = centralManager else {
            result(FlutterError(code: "BLUETOOTH_NOT_INITIALIZED", message: "Bluetooth manager is not initialized", details: nil))
            return
        }

        centralManager.stopScan()
        result(true) // Notify Flutter that the scan has been stopped
        print("Stopped scanning.")
    }

    // MARK: - Connect to Device
    private func connectToDevice(address: String, result: @escaping FlutterResult) {
        if let peripheral = discoveredPeripherals.first(where: { $0.identifier.uuidString == address }) {
            centralManager?.connect(peripheral, options: nil)
            flutterResult = result
        } else {
            result(FlutterError(code: "DEVICE_NOT_FOUND", message: "Device not found", details: nil))
        }
    }

    // MARK: - Disconnect from Device
    private func disconnectFromDevice(result: @escaping FlutterResult) {
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
            connectedPeripheral = nil
            result(true)
        } else {
            result(false)
        }
    }

    // MARK: - Print Image Bytes (Flutter-side byte array)
private func printImageBytes(result: @escaping FlutterResult, bytes: FlutterStandardTypedData) {
    print("insideAppDelegate print image method")

    // Check if connectedPeripheral and printCharacteristic are set
    guard let connectedPeripheral = connectedPeripheral else {
        print("Error: connectedPeripheral is nil.")
        result(FlutterError(code: "NOT_CONNECTED", message: "Not connected to a device", details: nil))
        return
    }

    guard let printCharacteristic = printCharacteristic else {
        print("Error: printCharacteristic is nil.")
        result(FlutterError(code: "NOT_CONNECTED", message: "Not connected to a device", details: nil))
        return
    }

    let imageData = bytes.data

    // Log image data size for debugging
    print("Received image data size: \(imageData.count) bytes")

    // Check if the image data is not empty
    guard !imageData.isEmpty else {
        print("Error: Image data is empty.")
        result(FlutterError(code: "EMPTY_BYTES", message: "No data to print", details: nil))
        return
    }

    // Ensure the data is in the correct format to send to the printer
    // You can add further processing here to format the image data if needed
    connectedPeripheral.writeValue(imageData, for: printCharacteristic, type: .withResponse)

    // Log the result of sending data to the printer
    print("Image data sent to printer.")

    // Respond back to Flutter with success
    result(true)
}


// MARK: - CBPeripheralDelegate Methods

func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    if let error = error {
        print("Error discovering services: \(error.localizedDescription)")
        return
    }

    // Loop through services to find the one with the printing characteristic
    if let services = peripheral.services {
        for service in services {
            // Discover characteristics for the service (or specify your service UUID)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
}

func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    if let error = error {
        print("Error discovering characteristics: \(error.localizedDescription)")
        return
    }

    // Locate the print characteristic by its UUID
    if let characteristics = service.characteristics {
        for characteristic in characteristics {
            if characteristic.uuid == CBUUID(string: "0000ff02-0000-1000-8000-00805f9b34fb") {  // Replace with your characteristic UUID
                printCharacteristic = characteristic
                print("Print characteristic found and set.")
                break
            }
        }
    }
}

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Bluetooth is ON")
        } else {
            print("Bluetooth is not available")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if !discoveredPeripherals.contains(peripheral) {
            discoveredPeripherals.append(peripheral)

            // Send each discovered device to Flutter via the event sink
            let deviceInfo: [String: Any] = [
                "name": peripheral.name ?? "Unknown",
                "address": peripheral.identifier.uuidString,
            ]

            eventSink?(deviceInfo)  // Send device info to Flutter
        }
    }

func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    print("Connected to \(peripheral.name ?? "Unknown Device")")
    connectedPeripheral = peripheral
    connectedPeripheral?.delegate = self
    connectedPeripheral?.discoverServices(nil)  // Discover all services or specify your service UUID here
}

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "Unknown Device")")
        flutterResult?(FlutterError(code: "CONNECTION_FAILED", message: error?.localizedDescription, details: nil))
    }
}

extension AppDelegate: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}