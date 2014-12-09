require 'opbeat/interfaces'

module Opbeat

  class ExceptionInterface < Interface

    name 'exception'
    attr_accessor :type
    attr_accessor :value
    attr_accessor :module

  end

  register_interface :exception => ExceptionInterface

end
