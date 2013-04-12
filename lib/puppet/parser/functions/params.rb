module Puppet::Parser::Functions
  newfunction(:params, :type => :rvalue) do |args|
    options = args[0]
    module_lookup = args[1]
    defaults = self.lookupvar("#{module_lookup}::params::defaults")

    # Bail out unless we have all required arguments
    raise Puppet::ParseError, "params() requires two arguments" unless args.length == 2

    # Bail out if passed data is not a hash
    raise Puppet::ParseError, "Passed options is not a hash" unless options.class == Hash

    # Bail out if default parameters do not exist
    raise Puppet::ParseError, "Default parameters do not exist for module '#{module_lookup}'" if defaults == nil

    # Bail out if defaults from module is not a hash
    raise Puppet::ParseError, "Defaults from module #{module_lookup} is not a hash" unless defaults.class == Hash

    defaults.merge(options)
  end
end
