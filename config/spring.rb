# frozen_string_literal: true

Spring.watch(
  ".ruby-version",
  ".rbenv-vars",
  ".env",
  "tmp/restart.txt",
  "tmp/caching-dev.txt"
)
