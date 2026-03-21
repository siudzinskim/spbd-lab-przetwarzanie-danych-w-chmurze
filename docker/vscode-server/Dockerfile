# Use the linuxserver/code-server image as the base
FROM linuxserver/code-server:latest

# Install necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    python3-venv \
    python3-poetry \
    sudo \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Set the PATH to include Poetry's bin directory
ENV PATH="/root/.local/bin:$PATH"

# Create a working directory
WORKDIR /app

# Copy pyproject.toml and poetry.lock
COPY pyproject.toml ./

# Install project dependencies with Poetry
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1
ENV VIRTUAL_ENV=/app/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN python3 -m venv $VIRTUAL_ENV \
  && poetry install --no-interaction

RUN activate-global-python-argcomplete
RUN register-python-argcomplete airflow >> ~/.bashrc

# Set the entrypoint to the custom script
ENTRYPOINT ["/init"]