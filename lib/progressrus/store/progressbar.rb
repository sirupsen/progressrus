require 'ruby-progressbar'

class Progressrus
  class Store
    class ProgressBar < Base
      def persist(progress, force: false, expires_at: false)
        bar(progress).progress = progress.count
      end

      def finish
      end

      def flush
      end

      private

      def bar(progress)
        @bar ||= ::ProgressBar.create(
          title: progress.id,
          total: progress.total,
          format: "%t: %a %e %P% Processed: %c from %C",
        )
      end
    end
  end
end
