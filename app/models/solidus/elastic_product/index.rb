# This static class exposes a configured interface to all class methods
# available from elastic search. Elastic's instance methods are available
# through {State}.
#
# The available class methods are defined in elasticsearch/model.rb under
# Model::METHODS = [:search, :mapping, :mappings, :settings, :index_name, :document_type, :import]
#
# @see elasticsearch-model/lib/elasticsearch/model/client.rb#L8
# @see elasticsearch-model/lib/elasticsearch/model/naming.rb#L8
# @see elasticsearch-model/lib/elasticsearch/model/indexing.rb#L83
# @see elasticsearch-model/lib/elasticsearch/model/searching.rb#L55

module Solidus::ElasticProduct
  class Index
    extend Elasticsearch::Model::Client::ClassMethods
    extend Elasticsearch::Model::Naming::ClassMethods
    extend Elasticsearch::Model::Indexing::ClassMethods
    extend Elasticsearch::Model::Searching::ClassMethods

    # Indexing is primary performed by the {Uploader}
    #
    # @see elasticsearch-model/lib/elasticsearch/model/adapters/active_record.rb
    extend Elasticsearch::Model::Importing::ClassMethods

    # mapping dynamic: 'strict' do
    #   indexes :foo do
    #     indexes :bar
    #   end
    #   indexes :baz
    # end

    index_name 'products'
    document_type 'spree/product'

    # Implement the importing adapter interface
    module Importing

      # Fetch batches of records from the database (used by the import method)
      #
      def __find_in_batches(options={}, &block)
        query = options.delete(:query)
        named_scope = options.delete(:scope)
        preprocess = options.delete(:preprocess)

        scope = State
        scope = scope.__send__(named_scope) if named_scope
        scope = scope.instance_exec(&query) if query

        scope.find_in_batches(options) do |batch|
          yield (preprocess ? self.__send__(preprocess, batch) : batch)
        end
      end

      def __transform
        lambda { |model|  { index: { _id: model.id, data: model.as_indexed_json } } }
      end
    end
    extend Importing


  end
end
