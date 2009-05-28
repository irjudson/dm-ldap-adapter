gem 'dm-core', '~> 0.9.10'
require 'dm-core'
require 'net/ldap'

module DataMapper
  module Adapters
    # The documentation for this adapter was taken from
    #
    # lib/dm-core/adapters/in_memory_adapter.rb
    #
    # Which is intended as a general source of documentation for the
    # implementation to be followed by all DataMapper adapters.  The
    # implementor is well advised to read over the adapter before
    # implementing their own.
    #
    class LdapAdapter < AbstractAdapter
      ##
      # Used by DataMapper to put records into a data-store: "INSERT"
      # in SQL-speak.  It takes an array of the resources (model
      # instances) to be saved. Resources each have a key that can be
      # used to quickly look them up later without searching, if the
      # adapter supports it.
      #
      # @param [Array<DataMapper::Resource>] resources
      #   The set of resources (model instances)
      #
      # @return [Integer]
      #   The number of records that were actually saved into the
      #   data-store
      #
      # @api semipublic
      def create(resources)

        created = 0
        resources.each do |resource|
          # Convert resources into LDAP (which just takes a hash!)
          ldap_obj = convert_resource_to_hash(resource)
          dn = resource.make_dn
          ldap_obj[:objectclass] = resource.objectclass

          if ldap_obj.nil? || dn.nil?
            puts "Problem converting resource to hash for LdapAdapter"
            return -1
          end

          # Call LDAP create
          begin
            @ldap.add(:dn => dn, :attributes => ldap_obj)
          rescue Net::LDAP::LdapError => e
            puts "There was an error adding the ldap object: ", e
            puts " => #{@ldap.get_operation_result.message}"
            return -1
          end

          # Accumulate successful create calls to return
          if @ldap.get_operation_result.code == 0
            created = created + 1
          else
            puts "LDAP Add Error: #{@ldap.get_operation_result.message}"
          end
        end

        # Return number created
        return created
      end

      ##
      # Used by DataMapper to update the attributes on existing
      # records in a data-store: "UPDATE" in SQL-speak. It takes a
      # hash of the attributes to update with, as well as a query
      # object that specifies which resources should be updated.
      #
      # @param [Hash] attributes
      #   A set of key-value pairs of the attributes to update the
      #   resources with.
      # @param [DataMapper::Query] query
      #   The query that should be used to find the resource(s) to update.
      #
      # @return [Integer]
      #   the number of records that were successfully updated
      #
      # @api semipublic
      def update(attributes, query)
        updated = 0

        # Convert query conditions to ldap filter
        filter = convert_conditions(query.conditions)

        # Convert attributes/query into LDAP
        entries = @ldap.search(:filter => filter)

        # Process updates (being careful to distinguish between add and update
        entries.each do |entry|
          existing = entry.attribute_names.map { |a| a.to_s }
          attributes.each do |attribute, value|
            property = attribute.field.to_s

            ops = []
            if existing.include?(property)
              ops << [:replace, attribute.field.to_sym, value]
            else
              ops << [:add, attribute.field.to_sym, value]
            end

            @ldap.modify(:dn => entry.dn, :operations => ops)

            if @ldap.get_operation_result.code == 0
              updated = updated + 1
            else
              puts "LDAP Modify Error: #{@ldap.get_operation_result.message}"
            end
          end
        end

        # Return Number updated
        return updated
      end

      ##
      # Look up a single record from the data-store. "SELECT ... LIMIT
      # 1" in SQL.  Used by Model#get to find a record by its
      # identifier(s), and Model#first to find a single record by some
      # search query.
      #
      # @param [DataMapper::Query] query
      #   The query to be used to locate the resource.
      #
      # @return [DataMapper::Resource]
      #   A Resource object representing the record that was found, or
      #   nil for no matching records.
      #
      # @api semipublic
      def read_one(query)
        # Call read_many(query)
        all_results = self.read_many(query)

        # Return first result
        return all_results.first
      end

      ##
      # Looks up a collection of records from the data-store: "SELECT" in SQL.
      # Used by Model#all to search for a set of records; that set is in a
      # DataMapper::Collection object.
      #
      # @param [DataMapper::Query] query
      #   The query to be used to seach for the resources
      #
      # @return [DataMapper::Collection]
      #   A collection of all the resources found by the query.
      #
      # @api semipublic
      def read_many(query)
        resources = Array.new

        # Convert query conditions to ldap filter
        filter = convert_conditions(query.conditions)

        # Convert attributes/query into LDAP
        @ldap.search(:filter => filter, :return_result => false) do |entry|
          values = query.fields.collect do |field|
            entry[field.field.to_sym].first
          end
          resources << query.model.load(values, query)
        end

        # Return Results
        resources
      end

      alias :read :read_many

      ##
      # Destroys all the records matching the given query. "DELETE" in SQL.
      #
      # @param [DataMapper::Query] query
      #   The query used to locate the resources to be deleted.
      #
      # @return [Integer]
      #   The number of records that were deleted.
      #
      # @api semipublic
      def delete(query)

        deleted = 0

        # Convert query conditions to ldap filter
        filter = convert_conditions(query.conditions)

        # Convert attributes/query into LDAP
        entries = @ldap.search(:filter => filter)

        # Call LDAP Delete
        entries.each do |entry|
          result = @ldap.delete(:dn => entry.dn)

          if @ldap.get_operation_result.code == 0
            deleted = deleted + 1
          else
            puts "LDAP Delete Error: #{@ldap.get_operation_result.message}"
          end
        end

        # Return number successfully deleted
        return deleted
      end

      private

      ##
      # Make a new instance of the adapter. The @model_records ivar is
      # the 'data-store' for this adapter. It is not shared amongst
      # multiple incarnations of this adapter, eg
      # DataMapper.setup(:default, :adapter => :in_memory);
      # DataMapper.setup(:alternate, :adapter => :in_memory) do not
      # share the data-store between them.
      #
      # @param [String, Symbol] name
      #   The name of the DataMapper::Repository using this adapter.
      # @param [String, Hash] uri_or_options
      #   The connection uri string, or a hash of options to set up
      #   the adapter
      #
      # @api semipublic
      def initialize(name, uri_or_options)
        super

        if uri_or_options.class
          @identity_maps = {}
        end

        # Let's play with Options
        @options = {
          :attributes => nil,
          :scope => Net::LDAP::SearchScope_WholeSubtree,
          :filter => nil,
          :auth => { :method => :simple }
        }

        if uri_or_options.is_a?(String)
          begin
            opt_array = URI.split(uri_or_options)
            @options[:scheme] = opt_array[0]
            @options[:auth][:username],@options[:auth][:password] = opt_array[1].split(':')
            @options[:host] = opt_array[2]
            @options[:port] = opt_array[3]

            # Registry from URI not used
            # @options[:registry] = opt_array[4]

            @options[:base] = opt_array[5]

            # Opaque from URI not used
            # @options[:opaque] = opt_array[6]

            # This is where the rest of the string is kept
            # According to the LDAP url spec it should look like
            # ?attributes?scope?filter, e.g.
            # ?uid?sub?(uid=username), however
            # URI strip appears to lose the first ?
            # So we parse it all out
            @options[:attributes],@options[:scope],@options[:filter] = opt_array[7].split('?')
            @options[:fragment] = opt_array[8]
          rescue InvalidURIError => e
            puts "Error parsing options for ldap adapter"
          end
        else
          @options.merge!(uri_or_options.dup)

          @options[:auth][:username] = @options[:username]
          @options[:auth][:password] = @options[:password]

          @options.delete(:adapter)
          @options.delete(:username)
          @options.delete(:password)
          @options.delete(:attributes)
          @options.delete(:filter)
        end

        # Deal with SSL stuff
        if @options[:scheme] == "ldaps" || @options[:port] == "636"
          @options[:encryption] = { :method => :simple_tls }
        end

        # Create the new LDAP client stub
        @ldap = Net::LDAP.new(@options)

        if ! @ldap.bind
          puts "Tried to bind with options: #{@options.inspect}"
          puts "Result: #{@ldap.get_operation_result.code}"
          puts "Message: #{@ldap.get_operation_result.message}"
        end
      end

      def convert_resource_to_hash(resource)
        result = Hash.new
        resource.send(:properties).each do |p|
          result[p.field.to_sym] = p.get!(resource) unless p.get!(resource).nil?
        end
        result
      end

      def convert_conditions(conditions)
        filters = Array.new
        conditions.each do |condition|
          case condition[0]
          when :eql
            filters << Net::LDAP::Filter.eq(condition[1].field(), condition[2].to_s)
          when :lt
            fle = Net::LDAP::Filter.le(condition[1].field(), condition[2].to_s)
            fe = Net::LDAP::Filter.eq(condition[1].field(), condition[2].to_s)
            filters << fle & ! fe
          when :gt
            fge = Net::LDAP::Filter.ge(condition[1].field(), condition[2].to_s)
            fe = Net::LDAP::Filter.eq(condition[1].field(), condition[2].to_s)
            filters << fge & ! fe
          when :lte
            filters << Net::LDAP::Filter.le(condition[1].field(), condition[2].to_s)
          when :gte
            filters << Net::LDAP::Filter.ge(condition[1].field(), condition[2].to_s)
          when :not  : puts "!"
            filters << Net::LDAP::Filter.ne(condition[1].field(), condition[2].to_s)
          when :like
            filters << Net::LDAP::Filter.eq(condition[1].field(), condition[2].to_s)
          else
            puts "Unknown condition: #{condition[0]}"
          end
        end

        # Put them all together with an AND
        ldap_filter = nil
        filters.each do |filter|
          if ldap_filter.nil?
            ldap_filter = filter
          else
            ldap_filter = ldap_filter & filter
          end
        end
        ldap_filter
      end
    end
  end
end
