module Progressrus
  module Store
    class NotImplementedError < StandardError; end

    class Base
      def persist(progresser)
        raise NotImplementedError
      end

      def scope(scope)
        raise NotImplementedError
      end

      def flush(scope, id = nil)
        raise NotImplementedError
      end
    end
  end
end
