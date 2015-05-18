require 'uber/options'
require "representable/parse_strategies"

module Representable
  # Created at class compile time. Keeps configuration options for one property.
  class Definition
    include Representable::Cloneable

    attr_reader :name
    alias_method :getter, :name # TODO: deprecate #getter in favour of #getter_method.

    def initialize(sym, options={}, &block)
      @options = {}
      # @options = Inheritable::Hash.new # allows deep cloning. we then had to set Pipeline cloneable.
      @name    = sym.to_s
      options  = options.clone

      # defaults:
      options[:parse_filter]  = Pipeline[*options[:parse_filter]]
      options[:render_filter] = Pipeline[*options[:render_filter]]
      options[:as]          ||= @name

      setup!(options, &block)





      # [:as, :getter, :setter, :class, :instance, :reader, :writer, :extend, :prepare, :if, :deserialize, :serialize,
      #  :render_filter, :parse_filter, :skip_parse, :skip_render]
      @readable = options[:readable]
      @writeable = options[:writeable]
      @if = @runtime_options[:if]
      @exec_context = options[:exec_context]
      @writer = @runtime_options[:writer]
      @reader = @runtime_options[:reader]
      @pass_options = options[:pass_options]
      @___getter = @runtime_options[:getter] # FIXME: what is this?

      @render_filter = @runtime_options[:render_filter]
      @parse_filter = @runtime_options[:parse_filter]
      @skip_render = @runtime_options[:skip_render]
      @skip_parse = @runtime_options[:skip_parse]

      @___prepare = @runtime_options[:prepare]
      @extend = @runtime_options[:extend]
      @instance = @runtime_options[:instance]
      @class = @runtime_options[:class]
      @as = @runtime_options[:as]
      @render_empty = options[:render_empty]
      @serialize = @runtime_options[:serialize]
      @deserialize = @runtime_options[:deserialize]
    end

    attr_reader :readable
    attr_reader :writeable
    attr_reader :if
    attr_reader :exec_context
    attr_reader :writer, :reader
    attr_reader :pass_options
    attr_reader :___getter
    attr_reader :render_filter
    attr_reader :parse_filter
    attr_reader :skip_render, :skip_parse
    attr_reader :___prepare
    attr_reader :extend, :instance#, :class
    attr_reader :as
    attr_reader :render_empty
    attr_reader :serialize, :deserialize

    #, :writeable, :if, :exec_context, :writer, :pass_options, :getter

    def merge!(options, &block)
      options = options.clone

      options[:parse_filter]  = @options[:parse_filter].push(*options[:parse_filter])
      options[:render_filter] = @options[:render_filter].push(*options[:render_filter])

      setup!(options, &block) # FIXME: this doesn't yield :as etc.
      self
    end

    def delete!(name)
      @runtime_options.delete(name)
      @options.delete(name)
      self
    end

    def [](name)
      @runtime_options[name]
    end

    def clone
      self.class.new(name, @options.clone)
    end

    def setter
      :"#{name}="
    end

    def typed?
      self[:class] or self[:extend] or self[:instance]
    end

    def representable?
      return if self[:representable] == false
      self[:representable] or typed?
    end

    def array?
      self[:collection]
    end

    def hash?
      self[:hash]
    end

    def has_default?
      @options.has_key?(:default)
    end

    def representer_module
      @options[:extend]
    end

    def create_binding(*args)
      self[:binding].call(self, *args)
    end

    def inspect
      state = (instance_variables-[:@runtime_options, :@name]).collect { |ivar| "#{ivar}=#{instance_variable_get(ivar)}" }
      "#<Representable::Definition ==>#{name} #{state.join(" ")}>"
    end

  private
    def setup!(options, &block)
      handle_extend!(options)
      handle_as!(options)

      # DISCUSS: we could call more macros here (e.g. for :nested).
      Representable::ParseStrategy.apply!(options)

      yield options if block_given?
      @options.merge!(options)

      runtime_options!(@options)
    end

    # wrapping dynamic options in Value does save runtime, as this is used very frequently (and totally unnecessary to wrap an option
    # at runtime, its value never changes).
    def runtime_options!(options)
      @runtime_options = {}

      for name, value in options
        value = Uber::Options::Value.new(value) if dynamic_options.include?(name)
        @runtime_options[name] = value
      end
    end






    def dynamic_options
      [:as, :getter, :setter, :class, :instance, :reader, :writer, :extend, :prepare, :if, :deserialize, :serialize, :render_filter, :parse_filter, :skip_parse, :skip_render]
    end

    def handle_extend!(options)
      mod = options.delete(:extend) || options.delete(:decorator) and options[:extend] = mod
    end

    def handle_as!(options)
      options[:as] = options[:as].to_s if options[:as].is_a?(Symbol) # Allow symbols for as:
    end
  end
end
