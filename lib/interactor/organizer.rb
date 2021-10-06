module Interactor
  # Public: Interactor::Organizer methods. Because Interactor::Organizer is a
  # module, custom Interactor::Organizer classes should include
  # Interactor::Organizer rather than inherit from it.
  #
  # Examples
  #
  #   class MyOrganizer
  #     include Interactor::Organizer
  #
  #     organizer InteractorOne, InteractorTwo
  #   end
  module Organizer
    # Internal: Install Interactor::Organizer's behavior in the given class.
    def self.included(base)
      base.class_eval do
        include Interactor

        extend ClassMethods
        include InstanceMethods
      end
    end

    class FilterableInteractorCollection
      attr_reader :collection

      def initialize
        @collection = []
      end

      def run(interactor_class, filters = {})
        interface = Interactor::Organizer::FilterableInteractor.new(interactor_class, filters)
        collection << interface if interface.interactor_class
      end

      def add(interactor_classes)
        interactor_classes.flatten.each { |interactor_class| run(interactor_class) }
      end

      def each(&block)
        collection.each(&block) if block
      end
    end

    class FilterableInteractor
      attr_reader :filters, :interactor_class

      CONDITIONAL_FILTERS = %i[if unless].freeze

      def initialize(interactor_class, options = {})
        @interactor_class = interactor_class
        @filters = options.select { |key, _value| CONDITIONAL_FILTERS.include?(key) }
      end

      def call!(target, context)
        return if check_conditionals(target, :if) == false
        return if check_conditionals(target, :unless) == true

        interactor_class.send(:call!, context)
      end

      private

      def check_conditionals(target, filter)
        resolve_option(target, filters[filter])
      end

      def resolve_option(target, opt)
        return unless opt

        return target.send(opt) if opt.is_a?(Symbol)
        return target.instance_exec(&opt) if opt.is_a?(Proc)
      end
    end

    # Internal: Interactor::Organizer class methods.
    module ClassMethods
      # Public: Declare Interactors to be invoked as part of the
      # Interactor::Organizer's invocation. These interactors are invoked in
      # the order in which they are declared.
      #
      # interactors - Zero or more (or an Array of) Interactor classes.
      #
      # Examples
      #
      #   class MyFirstOrganizer
      #     include Interactor::Organizer
      #
      #     organize InteractorOne, InteractorTwo
      #   end
      #
      #   class MySecondOrganizer
      #     include Interactor::Organizer
      #
      #     organize [InteractorThree, InteractorFour]
      #   end
      #
      # Returns nothing.
      def organize(*interactors, &block)
        organized.add(interactors) if interactors
        organized.instance_eval(&block) if block
        organized
      end

      # Internal: An Array of declared Interactors to be invoked.
      #
      # Examples
      #
      #   class MyOrganizer
      #     include Interactor::Organizer
      #
      #     organize InteractorOne, InteractorTwo
      #   end
      #
      #   MyOrganizer.organized
      #   # => [InteractorOne, InteractorTwo]
      #
      # Returns an Array of Interactor classes or an empty Array.
      def organized
        @organized ||= Interactor::Organizer::FilterableInteractorCollection.new
      end
    end

    # Internal: Interactor::Organizer instance methods.
    module InstanceMethods
      # Internal: Invoke the organized Interactors. An Interactor::Organizer is
      # expected not to define its own "#call" method in favor of this default
      # implementation.
      #
      # Returns nothing.
      def call
        self.class.organized.each do |interactor|
          interactor.call!(self, context)
        end
      end
    end
  end
end
