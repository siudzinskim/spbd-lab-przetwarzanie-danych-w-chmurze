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

# Install gcloud
RUN apt-get update && apt-get install -y apt-transport-https ca-certificates gnupg curl
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
    tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

RUN apt-get update && apt-get install -y google-cloud-cli

# Set the entrypoint to the custom script
ENTRYPOINT ["/init"]