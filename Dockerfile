# Use a base Erlang/OTP image
FROM erlang:24

# Set the working directory inside the container
WORKDIR /app

# Copy the rebar3 files into the container
COPY rebar.config rebar.lock ./

# Copy the application source code into the container
COPY src/ ./src

# Compile the Erlang application using Rebar3
RUN rebar3 compile

# Expose the desired ports
EXPOSE 4123 4234

# Start the Erlang application
CMD ["rebar3", "shell"]