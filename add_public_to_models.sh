#!/bin/bash

# Add public to all class declarations in DatabaseManager.swift
sed -i.bak 's/^class StepObj:/public class StepObj:/g' WatchProtocolSDK/Models/DatabaseManager.swift
sed -i '' 's/^class HeartObj:/public class HeartObj:/g' WatchProtocolSDK/Models/DatabaseManager.swift
sed -i '' 's/^class BloodObj:/public class BloodObj:/g' WatchProtocolSDK/Models/DatabaseManager.swift
sed -i '' 's/^class OxgenObj:/public class OxgenObj:/g' WatchProtocolSDK/Models/DatabaseManager.swift
sed -i '' 's/^class SleepObj:/public class SleepObj:/g' WatchProtocolSDK/Models/DatabaseManager.swift
sed -i '' 's/^class DatabaseManager {$/public class DatabaseManager {/g' WatchProtocolSDK/Models/DatabaseManager.swift
sed -i '' 's/    static let shared/    public static let shared/g' WatchProtocolSDK/Models/DatabaseManager.swift

echo "✅ Added public modifiers to all classes in DatabaseManager.swift"
