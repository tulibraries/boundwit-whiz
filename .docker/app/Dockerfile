# hadolint ignore=DL3006,DL3026
ARG BASE_IMAGE="harbor.k8s.temple.edu/library/ruby:4.0-alpine"

# ==========================================
# STAGE 1: Builder
# ==========================================
# hadolint ignore=DL3006,DL3026
FROM "${BASE_IMAGE}" AS builder

# Switch to root to allow package installation
USER 0

WORKDIR /app

# Set build arguments and build-time env
ARG RAILS_ENV=production
# hadolint ignore=DL3064
ENV RAILS_ENV=${RAILS_ENV} \
    SECRET_KEY_BASE_DUMMY=1

# Install all development headers and compilers needed for compilation
RUN apk add -U --no-cache \
    bash=5.3.9-r1 \
    build-base=0.5-r4 \
    git=2.54.0-r0 \
    yaml=0.2.5-r2 \
    yaml-dev=0.2.5-r2 \
    libxslt-dev=1.1.43-r3 \
    libffi-dev=3.5.2-r1 \
    postgresql17-dev=17.11-r0 \
    tzdata=2026c-r0

# Cache-friendly dependency layout
COPY Gemfile Gemfile.lock ./

# Install packages conditional on environment
RUN if [ "${RAILS_ENV}" = "production" ]; then bundle config set --local without "development test"; fi && \
    bundle install --jobs=8

# Copy the rest of the application
COPY . .

# Compile assets using the dummy secret key flag and purge unnecessary artifacts
RUN bundle exec rails assets:precompile && \
    find "$GEM_HOME" -name Gemfile.lock -exec rm "{}" \;

# Switch back to an unprivileged shell user at the end of Stage 1 to pass DL3002
USER 65534


# ==========================================
# STAGE 2: Final Runner
# ==========================================
# hadolint ignore=DL3006,DL3026
FROM "${BASE_IMAGE}" AS runner

WORKDIR /app

# Switch to root to configure native dependencies and directory security layers
USER 0

ARG RAILS_ENV=production
ENV RAILS_ENV=${RAILS_ENV} \
    LD_PRELOAD="libjemalloc.so.2" \
    MALLOC_CONF="dirty_decay_ms:1000,narenas:2,background_thread:true" \
    RUBY_YJIT_ENABLE="1"

# Install production-only native packages (gcompat preserves M1/Nokogiri compatibility)
RUN apk add -U --no-cache \
    bash=5.3.9-r1 \
    jemalloc=5.3.0-r6 \
    libc6-compat=1.1.0-r4 \
    libxslt=1.1.43-r3 \
    postgresql17-client=17.11-r0 \
    shared-mime-info=2.4-r7 \
    tzdata=2026c-r0

# Bring over pre-compiled vendor files and optimized gems from the builder stage
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app

# Build and protect production temporary directories and logging structures
RUN rm -rf /var/cache/apk/ && \
    mkdir -p /secure-tmp /secure-tmp/log && \
    chown -R 65534:65534 /secure-tmp && \
    chmod 700 /secure-tmp /secure-tmp/log

# Drop to secure unprivileged runtime system user context
USER 65534:65534

# Entrypoint prepares the database.
ENTRYPOINT ["/app/bin/docker-entrypoint"]

# Start server via Thruster by default, this can be overwritten at runtime
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
