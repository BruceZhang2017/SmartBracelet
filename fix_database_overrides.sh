#!/bin/bash

# Add public to all override methods in DatabaseManager.swift
sed -i '' 's/^    override static func primaryKey/    public override static func primaryKey/g' WatchProtocolSDK/Models/DatabaseManager.swift
sed -i '' 's/^    override var description/    public override var description/g' WatchProtocolSDK/Models/DatabaseManager.swift

echo "✅ Added public modifiers to override methods in DatabaseManager.swift"
