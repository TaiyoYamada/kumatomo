# Ollama Docker Configuration

This directory contains the Docker configuration for running Ollama in the development environment.

## Overview

The Ollama setup consists of two services:
- `ollama`: The main Ollama service that provides the AI API
- `ollama-init`: An initialization container that downloads the default model

## Configuration

### Environment Variables

The following environment variables can be configured in your `.env` file:

- `AI_PROVIDER=ollama` - Set the AI provider to use Ollama
- `OLLAMA_URL=http://ollama:11434` - URL for the Ollama service
- `OLLAMA_MODEL=gemma3:4b` - Default model to download and use
- `FORWARD_OLLAMA_PORT=11434` - Port to expose Ollama on the host

### Default Model

By default, the system uses the `gemma3:4b` model. You can change this by setting the `OLLAMA_MODEL` environment variable to any supported Ollama model:

- `gemma3:4b` (default)
- `llama2` (~3.8GB)
- `llama2:7b` (7B parameter model)
- `llama2:13b` (13B parameter model)
- `codellama` (Code-focused model)
- `mistral` (Mistral 7B model)

## Usage

### Starting the Services

```bash
# Start all services including Ollama
docker-compose up -d

# Start only Ollama services
docker-compose up -d ollama ollama-init
```

### Checking Status

```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# View Ollama logs
docker-compose logs ollama

# View initialization logs
docker-compose logs ollama-init
```

### Manual Model Management

```bash
# Connect to Ollama container
docker-compose exec ollama bash

# List available models
ollama list

# Pull a specific model
ollama pull gemma3:4b

# Run a model interactively
ollama run gemma3:4b
```

## Troubleshooting

### Model Download Issues

If the model download fails:

1. Check your internet connection
2. Verify the model name is correct
3. Try downloading manually:
   ```bash
   docker-compose exec ollama ollama pull gemma3:4b
   ```

### Service Not Starting

If Ollama fails to start:

1. Check Docker logs: `docker-compose logs ollama`
2. Verify port 11434 is not in use
3. Ensure sufficient disk space for models

### Performance Issues

- Models require significant RAM (4GB+ recommended)
- First-time model download can be slow
- Consider using smaller models for development

## File Structure

```
docker/ollama/
├── README.md           # This documentation
└── init-ollama.sh      # Model initialization script
```

## Integration with Laravel

The Laravel application connects to Ollama using the `OllamaProvider` class, which communicates with the Ollama API at `http://ollama:11434`.

Environment configuration in Laravel:
- Set `AI_PROVIDER=ollama` in your `.env` file
- The `OLLAMA_URL` should point to the Docker service: `http://ollama:11434`