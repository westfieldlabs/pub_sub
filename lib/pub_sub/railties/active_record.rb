module PubSub
  module Railties
    module ActiveRecord
      def self.included(klass)
        klass.send :include, InstanceMethods
        klass.send :extend, ClassMethods

        klass.after_save :publish_changes, if: -> { changed? }
      end

      module InstanceMethods
        def publish_changes
          async = self.class.publisher_async
          self.class.publisher_class.new(self).publish(async: async)
        end
      end

      module ClassMethods
        attr_accessor :publisher_class, :publisher_async

        def publish_changes_with(publisher, async: false)
          self.publisher_class = pub_sub_publisher_class(publisher)
          self.publisher_async = async
        end

        def pub_sub_publisher_class(publisher)
          publisher.to_s.classify.constantize
        end
      end
    end
  end
end
