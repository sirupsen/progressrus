module Enumerable
  def with_progress(**args, &block)
    if block_given?
      progresser = progress(args)
      begin
        ret = each { |*o|
          res = yield(*o)
          progresser.tick
          res
        }
      rescue
        progresser.fail
        raise
      end
      progresser.complete
      ret
    else
      enum_for(:with_progress, args)
    end
  end

  private
  def progress(args)
    @progress ||= begin
      # Lazily read the size, for some enumerable this may be quite expensive and
      # using this method should come with a warning in the documentation.
      total = self.size unless args[:total]
      @progress = Progressrus.new({total: total}.merge(args))
    end
  end
end
