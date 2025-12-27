#!/bin/bash

# Add public to all CBCentralManagerDelegate and CBPeripheralDelegate methods
sed -i '' 's/^    func centralManagerDidUpdateState/    public func centralManagerDidUpdateState/g' WatchProtocolSDK/Core/XGZTBlueToothManager.swift
sed -i '' 's/^    func centralManager/    public func centralManager/g' WatchProtocolSDK/Core/XGZTBlueToothManager.swift
sed -i '' 's/^    func peripheral(/    public func peripheral(/g' WatchProtocolSDK/Core/XGZTBlueToothManager.swift
sed -i '' 's/^    func peripheralIsReady/    public func peripheralIsReady/g' WatchProtocolSDK/Core/XGZTBlueToothManager.swift

echo "✅ Added public modifiers to all delegate methods"
