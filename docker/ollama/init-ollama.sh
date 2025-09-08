#!/bin/bash

# Ollama initialization script for development environment
# This script downloads and sets up the default model for local development

set -e

echo "Starting Ollama initialization..."

# Set Ollama host for client commands
export OLLAMA_HOST=${OLLAMA_HOST:-http://ollama:11434}

# Wait for Ollama service to be ready
echo "Waiting for Ollama service to start at $OLLAMA_HOST..."
until curl -f "$OLLAMA_HOST/api/tags" >/dev/null 2>&1; do
    echo "Waiting for Ollama to be ready..."
    sleep 5
done

echo "Ollama service is ready!"

# Set default model from environment variable or use gemma3:4b as fallback
MODEL_NAME=${OLLAMA_MODEL:-gemma3:4b}

echo "Checking if model '$MODEL_NAME' is already available..."

# Check if the model is already downloaded
if ollama list | grep -q "$MODEL_NAME" 2>/dev/null; then
    echo "Model '$MODEL_NAME' is already available."
else
    echo "Downloading model '$MODEL_NAME'... This may take a while."
    ollama pull "$MODEL_NAME"
    echo "Model '$MODEL_NAME' downloaded successfully!"
fi

# Test the model with a simple prompt
echo "Testing model with a simple prompt..."
echo "Hello, I am Kumamon AI!" | ollama run "$MODEL_NAME" || echo "Model test completed (output may vary)"

echo "Ollama initialization completed successfully!"
echo "Available models:"
ollama list || echo "Could not list models, but initialization completed"

echo "Ollama is ready for development use!"