#!/bin/bash

# Path to the project file
PROJECT_FILE="LGS Kocum PRO.xcodeproj/project.pbxproj"

# Check if the project file exists
if [ ! -f "$PROJECT_FILE" ]; then
    echo "Error: Project file not found at $PROJECT_FILE"
    exit 1
fi

# Check if the Documentation catalog is already added
if grep -q "Documentation.docc" "$PROJECT_FILE"; then
    echo "Documentation catalog is already added to the project."
    exit 0
fi

# Add the Documentation catalog to the project
# This is a simplified approach - in a real scenario, you might want to use xcodeproj Ruby gem
# or manually add the folder through Xcode's UI

echo "Adding Documentation catalog to the project..."

# Create a backup of the project file
cp "$PROJECT_FILE" "${PROJECT_FILE}.backup"

# Add the Documentation catalog to the project (simplified approach)
# Note: This is a basic implementation and might need adjustments

# 1. Add the group reference
sed -i '' '/Begin PBXGroup section/,/End PBXGroup section/ {
    /LGS Kocum PRO\/LGS Kocum PRO/ {
        n
        a \			3B1D7D5D2A1B2C3D4E5F6A7B8C9D0E1F2 = {isa = PBXFileReference; lastKnownFileType = folder.documentationcatalog; name = Documentation.docc; path = "Documentation.docc"; sourceTree = "<group>"; };
    }
}' "$PROJECT_FILE"

# 2. Add the file reference to the main group
sed -i '' '/children = (/ {
    /LGS Kocum PRO\/LGS Kocum PRO/ {
        n
        a \				3B1D7D5D2A1B2C3D4E5F6A7B8C9D0E1F2 /* Documentation.docc */,
    }
}' "$PROJECT_FILE"

echo "Documentation catalog has been added to the project."
echo "Please open the project in Xcode and verify the changes."
echo "You might need to manually add the Documentation catalog through Xcode's UI if this script didn't work as expected."
