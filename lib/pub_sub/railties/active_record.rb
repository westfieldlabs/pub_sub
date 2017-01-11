module PubSub
  module Railties
    module ActiveRecord
      def self.included(klass)
        klass.send :include, InstanceMethods
        klass.send :extend, ClassMethods

        # explicit cases that mark a record to be published
        klass.after_save :__pubsub_mark_to_publish!, if: :changed?
        klass.after_destroy :__pubsub_mark_to_publish!
        klass.after_touch :__pubsub_mark_to_publish!

        klass.after_commit :publish_changes, if: :__pubsub_marked_to_publish?
      end

      module InstanceMethods
        def __pubsub_mark_to_publish!
          @__pubsub_changes_to_publish = true
        end

        def __pubsub_marked_to_publish?
          @__pubsub_changes_to_publish
        end

        def publish_changes
          @__pubsub_changes_to_publish = false
          return true unless self.class.publisher_class

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
