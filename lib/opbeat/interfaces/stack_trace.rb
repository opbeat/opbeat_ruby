require 'opbeat/interfaces'

module Opbeat

  class StacktraceInterface < Interface

    name 'stacktrace'
    attr_accessor :frames, :default => []

    def initialize(*arguments)
      self.frames = []
      super(*arguments)
    end

    def to_hash
      data = super
      data['frames'] = data['frames'].map{|frame| frame.to_hash}
      data
    end

    def frame(attributes=nil, &block)
      Frame.new(attributes, &block)
    end

    # Not actually an interface, but I want to use the same style
    class Frame < Interface
      attr_accessor :abs_path
      attr_accessor :filename
      attr_accessor :function
      attr_accessor :vars, :default => {}
      attr_accessor :pre_context, :default => []
      attr_accessor :post_context, :default => []
      attr_accessor :context_line
      attr_accessor :lineno

      def to_hash
        data = super
        data.delete('vars') unless self.vars && !self.vars.empty?
        data.delete('pre_context') unless self.pre_context && !self.pre_context.empty?
        data.delete('post_context') unless self.post_context && !self.post_context.empty?
        data.delete('context_line') unless self.context_line && !self.context_line.empty?
        data
      end
    end

  end

  register_interface :stack_trace => StacktraceInterface

end
