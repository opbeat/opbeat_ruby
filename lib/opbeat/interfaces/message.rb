require 'opbeat/interfaces'

module Opbeat

  class MessageInterface < Interface

    name 'param_message'
    attr_accessor :message
    attr_accessor :params

    def initialize(*arguments)
      self.params = []
      super(*arguments)
    end
  end

  register_interface :message => MessageInterface

end
