module FakeRiak
  extend self

  def docs
    @docs ||= Set.new
  end

  def install
    Riak::RObject.class_eval do
      unless instance_methods.map(&:intern).include? :original_store
        alias original_store store
      end

      def store(*args)
        FakeRiak.docs << [@bucket.name, @key]
        original_store *args
      end
    end
  end

  def cleanup
    docs.delete_if do |bucket, key|
      Centurion.db.bucket(bucket).delete key
    end
  end
end
