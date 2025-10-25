module MainUtils
  def self.safe_value(value)
    value.nil? || value.empty? ? "NOT FOUND" : value
  end
end