FROM python:3.8-slim

# Set the working directory inside the container
WORKDIR /app

# Install dependencies
RUN pip install rasa rasa-sdk

# Copy project files into the container
COPY . .
