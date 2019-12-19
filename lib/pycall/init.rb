module PyCall
  def self.const_missing(name)
    case name
    when :PyPtr, :PyTypePtr, :PyObjectWrapper, :PYTHON_DESCRIPTION, :PYTHON_VERSION
      PyCall.init
      const_get(name)
    else
      super
    end
  end

  module LibPython
    def self.const_missing(name)
      case name
      when :API, :Conversion, :Helpers, :PYTHON_DESCRIPTION, :PYTHON_VERSION
        PyCall.init
        const_get(name)
      else
        super
      end
    end
  end

  def self.init(python = ENV['PYTHON'])
    return false if LibPython.instance_variable_defined?(:@handle)
    class << PyCall
      remove_method :const_missing
    end
    class << PyCall::LibPython
      remove_method :const_missing
    end

    ENV['PYTHONPATH'] = [ File.expand_path('../python', __FILE__), ENV['PYTHONPATH'] ].compact.join(File::PATH_SEPARATOR)

    puts 'going to find_libpython'
    LibPython.instance_variable_set(:@handle, LibPython::Finder.find_libpython(python))
    puts 'done find_libpython'
    class << LibPython
      undef_method :handle
      attr_reader :handle
    end

    begin
      major, minor, _ = RUBY_VERSION.split('.')
      require "#{major}.#{minor}/pycall.so"
    rescue LoadError
      require 'pycall.so'
    end
    puts 'boom 1'

    require 'pycall/dict'
    require 'pycall/list'
    require 'pycall/slice'
    puts 'boom 2'
    const_set(:PYTHON_VERSION, LibPython::PYTHON_VERSION)
    const_set(:PYTHON_DESCRIPTION, LibPython::PYTHON_DESCRIPTION)
    puts 'boom 3'
    true
  end
end
