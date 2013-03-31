require 'opbeat/interfaces'

module Opbeat

  class MessageInterface < Interface

    name 'param_message'
    property :message, :required => true
    property :params

    def initialize(*arguments)
      self.params = []
      super(*arguments)
    end
  end

  register_interface :message => MessageInterface

end
