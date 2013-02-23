require 'opbeat/interfaces'

module Opbeat

  class ExceptionInterface < Interface

    name 'exception'
    property :type, :required => true
    property :value, :required => true
    property :module

  end

  register_interface :exception => ExceptionInterface

end
