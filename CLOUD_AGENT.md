# Cloud Agent Integration

## Overview
Companion now supports both on-device and cloud-based LLM inference, allowing users to choose between privacy-focused local processing and powerful cloud models.

## Architecture

### Service Protocol
All LLM services implement the `LLMServiceProtocol`:
- `LLMService`: On-device MLX-based inference
- `CloudLLMService`: Cloud API-based inference (OpenAI-compatible)

### Service Manager
`LLMServiceManager` handles switching between service types and maintains separate instances of each service.

## Usage

### Switching Between Services
Users can switch between on-device and cloud models via the settings menu in the Chat view:
1. Tap the ellipsis (⋯) icon in the navigation bar
2. Select "Model" from the menu
3. Choose between "On-Device" or "Cloud"

### Setting Up Cloud API
To use cloud models:
1. Switch to "Cloud" mode in settings
2. Tap "Set API Key" in the settings menu
3. Enter your OpenAI API key
4. The key is stored securely in UserDefaults

### API Key Storage
- API keys are stored locally on the device in UserDefaults
- **Security Note**: For production use, consider migrating to iOS Keychain for encrypted storage
- Keys can be set via UserDefaults key: `cloudAPIKey`
- Environment variable `OPENAI_API_KEY` is also checked on startup

## Cloud Service Features

### Streaming Responses
Cloud responses are streamed in real-time, similar to on-device inference:
- SSE (Server-Sent Events) format parsing
- Real-time token counting and speed statistics
- Cancellation support

### Error Handling
The cloud service includes robust error handling:
- API key validation
- HTTP error reporting with status codes
- Network timeout handling
- Graceful cancellation

### Supported Endpoints
By default, the cloud service uses OpenAI's API:
- Default endpoint: `https://api.openai.com/v1/chat/completions`
- Default model: `gpt-4`
- Compatible with any OpenAI-compatible API

## Code Examples

### Generating with Cloud Service
```swift
let serviceManager = LLMServiceManager()
serviceManager.currentServiceType = .cloud
serviceManager.setCloudAPIKey("sk-...")

// Generate is called the same way for both services
let service = serviceManager.currentService
service.generate(prompt: "Hello", session: session, modelContext: context)
```

### Custom Cloud Endpoint
```swift
let cloudService = CloudLLMService(
    apiEndpoint: "https://custom-api.example.com/v1/chat/completions",
    apiKey: "your-api-key"
)
```

## UI Components

### Model Info Sheet
Updated to show different information based on service type:
- On-Device: Model name, GPU memory usage, performance stats
- Cloud: Service name, connection status, performance stats

### API Key Sheet
New component for securely entering and saving API keys:
- SecureField for password-style input
- Validation to ensure key is not empty
- Cancel/Save actions

## Privacy Considerations

### On-Device Mode
- All processing happens locally on the device
- No data leaves the device
- Requires significant device memory and processing power

### Cloud Mode
- Messages are sent to the cloud API for processing
- Subject to the cloud provider's privacy policy
- Requires internet connection
- May incur API costs

## Future Enhancements

Potential improvements for the cloud agent feature:
- **Security**: Migrate API key storage from UserDefaults to iOS Keychain for encrypted storage
- Support for additional cloud providers (Anthropic, Google, etc.)
- Custom model selection in UI
- Temperature and parameter controls
- Usage tracking and cost estimation
- Offline mode with automatic fallback to on-device
- Batch request optimization
- Response caching for repeated queries
