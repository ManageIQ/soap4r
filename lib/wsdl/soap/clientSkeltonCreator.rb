# encoding: ASCII-8BIT
# WSDL4R - Creating client skelton code from WSDL.
# Copyright (C) 2000-2007  NAKAMURA, Hiroshi <nahi@ruby-lang.org>.

# This program is copyrighted free software by NAKAMURA, Hiroshi.  You can
# redistribute it and/or modify it under the same terms of Ruby's license;
# either the dual license version in 2003, or any later version.


require 'wsdl/info'
require 'wsdl/soap/classDefCreatorSupport'


module WSDL
module SOAP


class ClientSkeltonCreator
  include ClassDefCreatorSupport

  attr_reader :definitions

  def initialize(definitions, name_creator, modulepath = nil)
    @definitions = definitions
    @name_creator = name_creator
    @modulepath = modulepath
  end

  def dump(service_name)
    services = @definitions.service(service_name)
    unless services
      raise RuntimeError.new("service not defined: #{service_name}")
    end
    result = ""
    if @modulepath
      result << "\n"
      modulepath = @modulepath.respond_to?(:lines) ? @modulepath.lines : @modulepath # RubyJedi: compatible with Ruby 1.8.6 and above      
      result << modulepath.collect { |ele| "module #{ele}" }.join("; ")
      result << "\n\n"
    end
    services.ports.each do |port|
      result << dump_porttype(port.porttype)
      result << "\n"
    end
    if @modulepath
      result << "\n\n"
      modulepath = @modulepath.respond_to?(:lines) ? @modulepath.lines : @modulepath # RubyJedi: compatible with Ruby 1.8.6 and above      
      result << modulepath.collect { |ele| "end" }.join("; ")
      result << "\n"
    end
    result
  end

private

  def dump_porttype(porttype)
    assigned_method = collect_assigned_method(@definitions, porttype.name, @modulepath)
    drv_name = mapped_class_basename(porttype.name, @modulepath)

    result = ""
    result << <<__EOD__
endpoint_url = ARGV.shift
obj = #{ drv_name }.new(endpoint_url)

# run ruby with -d to see SOAP wiredumps.
obj.wiredump_dev = STDERR if $DEBUG

__EOD__
    element_definitions = @definitions.collect_elements
    binding = porttype.find_binding
    if binding
      binding.operations.each do |op_bind|
        operation = op_bind.find_operation
        if operation.nil?
          warn("operation not found for binding: #{op_bind}")
          next
        end
        name = assigned_method[op_bind.boundid] || operation.name
        result << dump_method_signature(name, operation, element_definitions)
        result << dump_input_init(operation.input) << "\n"
        result << dump_operation(name, operation) << "\n\n"
      end
    end
    result
  end

  def dump_operation(name, operation)
    input = operation.input
    "puts obj.#{ safemethodname(name) }#{ dump_inputparam(input) }"
  end

  def dump_input_init(input)
    result = input.find_message.parts.collect { |part|
      safevarname(part.name)
    }.join(" = ")
    if result.empty?
      ""
    else
      result << " = nil"
    end
    result
  end
end


end
end
