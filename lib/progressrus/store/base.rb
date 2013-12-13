class Progressrus
  class Store
    class NotImplementedError < StandardError; end

    class Base
      def persist(progress)
        raise NotImplementedError
      end

      def scope(scope)
        raise NotImplementedError
      end

      def find(scope, id)
        raise NotImplementedError
      end

      def flush(scope, id = nil)
        raise NotImplementedError
      end
    end
  end
end
