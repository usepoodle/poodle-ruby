# frozen_string_literal: true

require_relative "base_error"

module Poodle
  # Exception raised when API rate limits are exceeded (429 Too Many Requests)
  #
  # @example Handling rate limit errors
  #   begin
  #     client.send_email(email)
  #   rescue Poodle::RateLimitError => e
  #     puts "Rate limit exceeded: #{e.message}"
  #     puts "Retry after: #{e.retry_after} seconds" if e.retry_after
  #     puts "Limit: #{e.limit}, Remaining: #{e.remaining}"
  #   end
  class RateLimitError < Error
    # @return [Integer, nil] seconds to wait before retrying
    attr_reader :retry_after

    # @return [Integer, nil] the rate limit
    attr_reader :limit

    # @return [Integer, nil] remaining requests
    attr_reader :remaining

    # @return [Integer, nil] time when the rate limit resets
    attr_reader :reset_time

    # Initialize a new RateLimitError
    #
    # @param message [String] the error message
    # @param retry_after [Integer, nil] seconds to wait before retrying
    # @param limit [Integer, nil] the rate limit
    # @param remaining [Integer, nil] remaining requests
    # @param reset_time [Integer, nil] time when the rate limit resets
    # @param context [Hash] additional context information
    def initialize(message = "Rate limit exceeded", **options)
      @retry_after = options[:retry_after]
      @limit = options[:limit]
      @remaining = options[:remaining]
      @reset_time = options[:reset_time]
      context = options.fetch(:context, {})

      rate_context = {
        error_type: "rate_limit_exceeded",
        retry_after: @retry_after,
        limit: @limit,
        remaining: @remaining,
        reset_time: @reset_time
      }.compact

      super(message, context: context.merge(rate_context), status_code: 429)
    end

    # Create a RateLimitError from response headers
    #
    # @param headers [Hash] HTTP response headers
    # @return [RateLimitError] the rate limit error
    def self.from_headers(headers)
      retry_after = extract_retry_after(headers)
      limit = extract_limit(headers)
      remaining = extract_remaining(headers)
      reset_time = extract_reset_time(headers)

      message = build_message(retry_after)
      context = build_context(limit, remaining, reset_time)

      new(
        message,
        retry_after: retry_after,
        limit: limit&.to_i,
        remaining: remaining&.to_i,
        reset_time: reset_time&.to_i,
        context: context
      )
    end

    # Extract retry-after value from headers
    #
    # @param headers [Hash] HTTP response headers
    # @return [Integer, nil] retry after seconds
    def self.extract_retry_after(headers)
      headers["retry-after"]&.to_i
    end

    # Extract rate limit from headers
    #
    # @param headers [Hash] HTTP response headers
    # @return [String, nil] rate limit value
    def self.extract_limit(headers)
      headers["X-RateLimit-Limit"] || headers["ratelimit-limit"]
    end

    # Extract remaining requests from headers
    #
    # @param headers [Hash] HTTP response headers
    # @return [String, nil] remaining requests value
    def self.extract_remaining(headers)
      headers["X-RateLimit-Remaining"] || headers["ratelimit-remaining"]
    end

    # Extract reset time from headers
    #
    # @param headers [Hash] HTTP response headers
    # @return [String, nil] reset time value
    def self.extract_reset_time(headers)
      headers["X-RateLimit-Reset"] || headers["ratelimit-reset"]
    end

    # Build error message
    #
    # @param retry_after [Integer, nil] retry after seconds
    # @return [String] error message
    def self.build_message(retry_after)
      message = "Rate limit exceeded."
      message += " Retry after #{retry_after} seconds." if retry_after
      message
    end

    # Build context hash
    #
    # @param limit [String, nil] rate limit
    # @param remaining [String, nil] remaining requests
    # @param reset_time [String, nil] reset time
    # @return [Hash] context hash
    def self.build_context(limit, remaining, reset_time)
      {
        limit: limit,
        remaining: remaining,
        reset_at: reset_time
      }.compact
    end

    private_class_method :extract_retry_after, :extract_limit, :extract_remaining,
                         :extract_reset_time, :build_message, :build_context

    # Get the time when the rate limit resets as a Time object
    #
    # @return [Time, nil] the reset time
    def reset_at
      return nil unless @reset_time

      Time.at(@reset_time)
    end
  end
end
