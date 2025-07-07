<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# EC Sensor Monitor - Flutter Android App Instructions

This is a Flutter Android application designed to connect to HC-05 Bluetooth modules and receive EC (Electrical Conductivity) sensor data from Arduino devices.

## Project Context

- **Target Platform**: Android only
- **Bluetooth Module**: HC-05
- **Data Format**: JSON (`{"ec": 2.15}`)
- **Sensor Type**: Electrical Conductivity (EC) sensor
- **Hardware**: Arduino Uno + EC sensor + HC-05 module

## Architecture Guidelines

- Use clean architecture with service layers
- Separate Bluetooth functionality into dedicated service classes
- Handle permissions properly for Android Bluetooth requirements
- Implement proper error handling and user feedback
- Follow Flutter best practices and Material Design 3

## Key Dependencies

- `flutter_bluetooth_serial` for Bluetooth communication
- `permission_handler` for managing Android permissions
- Standard Flutter Material UI components

## Code Style

- Use proper null safety
- Implement stream-based communication for real-time updates
- Handle connection states appropriately
- Provide clear user feedback for all operations
- Maintain responsive UI during Bluetooth operations

## Future Considerations

When extending this app, consider:
- Data logging capabilities
- Multiple sensor support
- Real-time graphing
- Export functionality
- Alert/notification systems
