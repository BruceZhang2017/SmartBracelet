#!/bin/bash

# Add public to all static func lines in XGZTCommands.swift
sed -i.bak 's/^    static func /    public static func /g' WatchProtocolSDK/Core/XGZTCommands.swift

echo "✅ Added public modifiers to all static methods in XGZTCommands.swift"
