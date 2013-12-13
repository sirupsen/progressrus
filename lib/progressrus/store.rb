class Progressrus
  class Store < Array
    def initialize(default)
      @default = default
      self << default
    end

    def default
      @default
    end

    def default!
      clear
      self << default
    end

    def find_by_name(name)
      return first if name == :first
      return last  if name == :last

      find { |store| store.name == name }
    end
  end
end
