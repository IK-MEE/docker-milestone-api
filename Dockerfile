# ─────────────────────────────
# Stage 1 — builder
# ─────────────────────────────
FROM ruby:3.3-alpine AS builder

RUN apk add --no-cache postgresql-dev build-base

WORKDIR /app

COPY Gemfile* ./
RUN bundle install

# ─────────────────────────────
# Stage 2 — final
# ─────────────────────────────
FROM ruby:3.3-alpine

# Install runtime library only
RUN apk add --no-cache postgresql-libs

# Create non-root user
RUN adduser -D appuser

WORKDIR /app

# Copy gems from builder
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Copy app code
COPY app.rb .

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- http://localhost:4567/health || exit 1

EXPOSE 4567

CMD ["ruby", "app.rb", "-o", "0.0.0.0"]