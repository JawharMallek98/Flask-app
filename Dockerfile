# Use the official Python image
FROM python:3.10-slim

# Set the working directory
WORKDIR /app

# Copy the requirements file
COPY requirements.txt .

# Install the application dependencies
RUN apt update
RUN apt upgrade
RUN pip install --upgrade pip
RUN apt-get install -y pkg-config
RUN apt-get install -y python3-dev default-libmysqlclient-dev build-essential
RUN pip install wheel
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY . .

# Expose the port that the app runs on (if not already specified in your Flask app)
EXPOSE 5000

# Start the application
CMD ["python", "app.py"]

