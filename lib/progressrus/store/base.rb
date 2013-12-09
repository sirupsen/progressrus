module Progressrus
  module Store
    class NotImplementedError < StandardError; end

    class Base
      def persist(progressrus)
        raise NotImplementedError
      end

      def scope(scope)
        raise NotImplementedError
      end

      def flush(scope)
        raise NotImplementedError
      end
    end
  end
end
