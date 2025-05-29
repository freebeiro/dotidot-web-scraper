# frozen_string_literal: true

module Api
  module V1
    class DataController < ApplicationController
      include RequestLogging

      # Override error handling for simplified API response format
      rescue_from ScraperErrors::ValidationError, with: :handle_validation_error
      rescue_from ScraperErrors::SecurityError, with: :handle_validation_error
      rescue_from ScraperErrors::NetworkError, with: :handle_network_error
      rescue_from ScraperErrors::ParsingError, with: :handle_validation_error
      rescue_from StandardError, with: :handle_standard_error

      # Handle both GET and POST requests
      def index
        handle_extraction_request
      end

      def create
        handle_extraction_request
      end

      private

      def handle_extraction_request
        validate_parameters!

        result = ScraperOrchestratorService.call(
          url: extraction_params[:url],
          fields: parse_fields
        )

        if result[:success]
          render_success(result[:data])
        else
          render_error(result[:error])
        end
      end

      def extraction_params
        if request.post?
          # For POST requests, parse JSON body
          JSON.parse(request.body.read).with_indifferent_access
        else
          # For GET requests, use query parameters
          params.permit(:url, :fields)
        end
      rescue JSON::ParserError
        raise ScraperErrors::ValidationError, "Invalid JSON in request body"
      end

      def validate_parameters!
        raise ScraperErrors::ValidationError, "URL parameter is required" if extraction_params[:url].blank?
        raise ScraperErrors::ValidationError, "fields parameter is required" if extraction_params[:fields].blank?
      end

      def parse_fields
        fields_param = extraction_params[:fields]

        if fields_param.is_a?(String)
          # Parse JSON string (for GET requests)
          JSON.parse(fields_param)
        elsif fields_param.is_a?(Hash)
          # Already a hash (for POST requests)
          fields_param
        else
          raise ScraperErrors::ValidationError, "Invalid fields format"
        end
      rescue JSON::ParserError
        raise ScraperErrors::ValidationError, "Invalid fields JSON format"
      end

      def render_success(data)
        render json: {
          success: true,
          data: data
        }, status: :ok
      end

      def render_error(error_message)
        render json: {
          success: false,
          error: error_message
        }, status: :bad_request
      end

      def handle_validation_error(error)
        render json: {
          success: false,
          error: error.message
        }, status: :bad_request
      end

      def handle_network_error(error)
        render json: {
          success: false,
          error: error.message
        }, status: :bad_gateway
      end

      def handle_standard_error(error)
        render json: {
          success: false,
          error: error.message
        }, status: :bad_request
      end
    end
  end
end
