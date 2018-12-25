module Protobuf
  module Field
    class BaseFieldMethodDefinitions

      def self.fully_qualified_name_string(selph)
        fully_qualified_name = ""
        fully_qualified_name << ":"
        fully_qualified_name << '"' if selph.fully_qualified_name.to_s.start_with?(".")
        fully_qualified_name << selph.fully_qualified_name.to_s
        fully_qualified_name << '"' if selph.fully_qualified_name.to_s.start_with?(".")
        fully_qualified_name
      end

      def self.define_base_set_method!(selph)
        selph.instance_eval <<~RUBY, __FILE__, __LINE__ + 1
          def set(message_instance, bytes)
            message_instance.set_field("#{selph.name}", decode(bytes), true, self)
          end
        RUBY
      end

      def self.define_map_set_method!(selph)
        selph.instance_eval <<~RUBY, __FILE__, __LINE__ + 1
          def set(message_instance, bytes)
            hash = message_instance["#{selph.name}"]
            entry = decode(bytes)
            # decoded value could be nil for an
            # enum value that is not recognized
            hash[entry.key] = entry.value unless entry.value.nil?
            hash[entry.key]
          end
        RUBY
      end

      def self.define_repeated_not_packed_set_method!(selph)
        selph.instance_eval <<~RUBY, __FILE__, __LINE__ + 1
          def set(message_instance, bytes)
            message_instance["#{selph.name}"] << decode(bytes)
          end
        RUBY
      end

      def self.define_repeated_packed_set_method!(selph)
        selph.instance_eval <<~RUBY, __FILE__, __LINE__ + 1
          def set(message_instance, bytes)
            array = message_instance["#{selph.name}"]
            stream = ::StringIO.new(bytes)

            if wire_type == ::Protobuf::WireType::VARINT
              array << decode(Varint.decode(stream)) until stream.eof?
            elsif wire_type == ::Protobuf::WireType::FIXED64
              array << decode(stream.read(8)) until stream.eof?
            elsif wire_type == ::Protobuf::WireType::FIXED32
              array << decode(stream.read(4)) until stream.eof?
            end
          end
        RUBY
      end

      def self.define_map_set_field!(selph)
        if selph.required?
          selph.instance_eval <<~RUBY, __FILE__, __LINE__ + 1
            def set_field(values, value, ignore_nil_for_repeated, message_instance)
              unless value.is_a?(Hash)
                fail TypeError, <<-TYPE_ERROR
                    Expected map value
                    Got '#{value.class}' for map protobuf field #{selph.name}
                TYPE_ERROR
              end

              if value.empty?
                values.delete(#{fully_qualified_name_string(selph)})
                message_instance._protobuf_message_required_field_tags << #{selph.tag}
              else
                message_instance._protobuf_message_required_field_tags.delete(#{selph.tag})
                values[#{fully_qualified_name_string(selph)}] ||= ::Protobuf::Field::FieldHash.new(self)
                values[#{fully_qualified_name_string(selph)}].replace(value)
              end
            end
          RUBY
        else
          selph.instance_eval <<~RUBY, __FILE__, __LINE__ + 1
            def set_field(values, value, ignore_nil_for_repeated, message_instance)
              unless value.is_a?(Hash)
                fail TypeError, <<-TYPE_ERROR
                    Expected map value
                    Got '#{value.class}' for map protobuf field #{selph.name}
                TYPE_ERROR
              end

              if value.empty?
                values.delete(#{fully_qualified_name_string(selph)})
              else
                values[#{fully_qualified_name_string(selph)}] ||= ::Protobuf::Field::FieldHash.new(self)
                values[#{fully_qualified_name_string(selph)}].replace(value)
              end
            end
          RUBY
        end
      end

      def self.define_repeated_set_field!(selph)
        if selph.required?
          selph.instance_eval <<~RUBY, __FILE__, __LINE__ + 1
            def set_field(values, value, ignore_nil_for_repeated, message_instance)
              if value.nil? && ignore_nil_for_repeated
                ::Protobuf.deprecator.deprecation_warning("['#{fully_qualified_name_string(selph)}']=nil", "use an empty array instead of nil")
                return
              end

              unless value.is_a?(Array)
                fail TypeError, <<-TYPE_ERROR
                    Expected repeated value of type '#{selph.type_class}'
                    Got '\#{value.class}' for repeated protobuf field #{selph.name}
                TYPE_ERROR
              end

              value = value.compact

              if value.empty?
                values.delete(#{fully_qualified_name_string(selph)})
                message_instance._protobuf_message_required_field_tags << #{selph.tag}
              else
                message_instance._protobuf_message_required_field_tags.delete(#{selph.tag})
                values[#{fully_qualified_name_string(selph)}] ||= ::Protobuf::Field::FieldArray.new(self)
                values[#{fully_qualified_name_string(selph)}].replace(value)
              end
            end
          RUBY
        else
          selph.instance_eval <<~RUBY, __FILE__, __LINE__ + 1
            def set_field(values, value, ignore_nil_for_repeated, message_instance)
              if value.nil? && ignore_nil_for_repeated
                ::Protobuf.deprecator.deprecation_warning("['#{fully_qualified_name_string(selph)}']=nil", "use an empty array instead of nil")
                return
              end

              unless value.is_a?(Array)
                fail TypeError, <<-TYPE_ERROR
                    Expected repeated value of type '#{selph.type_class}'
                    Got '\#{value.class}' for repeated protobuf field #{selph.name}
                TYPE_ERROR
              end

              value = value.compact

              if value.empty?
                values.delete(#{fully_qualified_name_string(selph)})
              else
                values[#{fully_qualified_name_string(selph)}] ||= ::Protobuf::Field::FieldArray.new(self)
                values[#{fully_qualified_name_string(selph)}].replace(value)
              end
            end
          RUBY
        end
      end

      def self.define_base_set_field!(selph)
        if selph.required?
          selph.instance_eval <<~RUBY, __FILE__, __LINE__ + 1
            def set_field(values, value, ignore_nil_for_repeated, message_instance)
              if value.nil?
                values.delete(#{fully_qualified_name_string(selph)})
                message_instance._protobuf_message_required_field_tags << #{selph.tag}
              else
                message_instance._protobuf_message_required_field_tags.delete(#{selph.tag})
                values[#{fully_qualified_name_string(selph)}] = coerce!(value)
              end
            end
          RUBY
        else
          selph.instance_eval <<~RUBY, __FILE__, __LINE__ + 1
            def set_field(values, value, ignore_nil_for_repeated, message_instance)
              if value.nil?
                values.delete(#{fully_qualified_name_string(selph)})
              else
                values[#{fully_qualified_name_string(selph)}] = coerce!(value)
              end
            end
          RUBY
        end
      end

      def self.define_base_field_and_present_p!(selph)
        selph.instance_eval <<~RUBY, __FILE__, __LINE__ + 1
          def field_and_present?(values)
            values[#{fully_qualified_name_string(selph)}].present?
          end
        RUBY
      end

      def self.define_bool_field_and_present_p!(selph)
        selph.instance_eval <<~RUBY, __FILE__, __LINE__ + 1
          BOOL_VALUES = [true, false].freeze unless defined?(BOOL_VALUES)

          def field_and_present?(values)
            BOOL_VALUES.include?(values[#{fully_qualified_name_string(selph)}])
          end
        RUBY
      end

      def self.define_base_field_p!(selph)
        selph.instance_eval <<~RUBY, __FILE__, __LINE__ + 1
          def field?(values)
            values.key?(#{fully_qualified_name_string(selph)})
          end
        RUBY
      end

      def self.define_repeated_field_p!(selph)
        selph.instance_eval <<~RUBY, __FILE__, __LINE__ + 1
          def field?(values)
            values.key?(#{fully_qualified_name_string(selph)}) && values[#{fully_qualified_name_string(selph)}].present?
          end
        RUBY
      end

      def self.define_field_value_from_values!(selph)
        selph.instance_eval <<~RUBY, __FILE__, __LINE__ + 1
          def value_from_values(values)
            values.fetch(#{fully_qualified_name_string(selph)}) { default_value }
          end
          alias :value_from_values_for_serialization value_from_values
        RUBY
      end

      def self.define_map_value_from_values!(selph)
        selph.instance_eval <<~RUBY, __FILE__, __LINE__ + 1
          def value_from_values(values)
            values[#{fully_qualified_name_string(selph)}] ||= ::Protobuf::Field::FieldHash.new(self)
          end

          def value_from_values_for_serialization(values)
            value = value_from_values(values)

            array = Array.new(value.size)
            value.each do |k, v|
              array << type_class.new(:key => k, :value => v)
            end

            array
          end
        RUBY
      end

      def self.define_repeated_value_from_values!(selph)
        selph.instance_eval <<~RUBY, __FILE__, __LINE__ + 1
          def value_from_values(values)
            values[#{fully_qualified_name_string(selph)}] ||= ::Protobuf::Field::FieldArray.new(self)
          end
          alias :value_from_values_for_serialization value_from_values
        RUBY
      end

    end
  end
end
