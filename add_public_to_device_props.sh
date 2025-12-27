#!/bin/bash

# Add public to all var properties in XGZTSwitchDevice.swift (but not inside functions)
# This targets properties at the class level
sed -i.bak 's/^    var /    public var /g' WatchProtocolSDK/Models/XGZTSwitchDevice.swift

echo "✅ Added public modifiers to all properties in XGZTSwitchDevice.swift"
