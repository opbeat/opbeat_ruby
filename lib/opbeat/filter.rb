module Opbeat
  class Filter
    MASK = '[FILTERED]'
    DEFAULT_FILTER = [/(authorization|password|passwd|secret)/i]

    def initialize(filters=nil)
      if defined?(::Rails)
        rails_filters = ::Rails.application.config.filter_parameters
        rails_filters = nil if rails_filters.count == 0
      end
      @filters = filters || rails_filters || DEFAULT_FILTER
    end

    def apply(value, key=nil, &block)
      if value.is_a?(Hash)
        value.each.inject({}) do |memo, (k, v)|
          memo[k] = apply(v, k, &block)
          memo
        end
      elsif value.is_a?(Array)
        value.map do |value|
          apply(value, key, &block)
        end
      else
        block.call(key, value)
      end
    end

    def sanitize(key, value)
      if !value.is_a?(String) || value.empty?
        value
      elsif @filters.any? { |filter| filter.is_a?(Regexp) ? filter.match(key) : filter.to_s == key.to_s }
        MASK
      else
        value
      end
    end

    def process_event_hash(data)
      return data unless data.has_key? 'http'
      if data['http'].has_key? 'data'
        data['http']['data'] = process_hash(data['http']['data'])
      end
      if data['http'].has_key? 'query_string'
        data['http']['query_string'] = process_string(data['http']['query_string'], '&')
      end
      if data['http'].has_key? 'cookies'
        data['http']['cookies'] = process_string(data['http']['cookies'], ';')
      end
      data
    end

    def process_hash(data)
      apply(data) do |key, value|
        sanitize(key, value)
      end
    end

    def process_string(str, separator='&')
      str.split(separator).map { |s| s.split('=') }.map { |a| a[0]+'='+sanitize(a[0], a[1]) }.join(separator)
    end
  end
end
