module Progressrus
  module Store
    class NotImplementedError < StandardError; end

    class Base
      def persist(progressrus)
        raise NotImplementedError
      end
    end
  end
end
