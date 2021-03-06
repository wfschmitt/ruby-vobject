require "vobject"
require "vobject/parameter"

class Vobject::Property
  attr_accessor :group, :prop_name, :params, :value, :multiple, :norm

  def <=>(another)
    if self.prop_name =~ /^VERSION$/i
      -1
    elsif another.prop_name =~ /^VERSION$/i
      1
    else
      self.to_norm <=> another.to_norm
    end
  end

  def initialize(key, options)
    if options.class == Array
      self.multiple = []
      options.each do |v|
        multiple << property_base_class.new(key, v)
        self.prop_name = key
      end
    else
      self.prop_name = key
      if options.nil? || options.empty?
        self.group = nil
        self.params = []
        self.value = nil
      else
        self.group = options[:group]
        self.prop_name = key
        unless options[:params].nil? || options[:params].empty?
          self.params = []
          options[:params].each do |k, v|
            params << parameter_base_class.new(k, v)
          end
        end
        # self.value = parse_value(options[:value])
        self.value = options[:value]
      end
    end
    self.norm = nil
    raise_invalid_initialization if key != name
  end

  def to_s
    if multiple.nil? || multiple.empty?
      ret = to_s_line
    else
      arr = []
      multiple.each do |x|
        arr << x.to_s_line
      end
      ret = arr.join("")
    end
    ret
  end

  def to_s_line
    line = group ? "#{group}." : ""
    line << name.to_s.tr("_", "-")

    (params || {}).each do |p|
      line << ";#{p}"
    end

    line << ":#{value}"

    line = Vobject::fold_line(line) << "\n"

    line
  end

  def to_norm
    if @norm.nil?
      if multiple.nil? || multiple.empty?
        ret = to_norm_line
      else
        arr = []
        multiple.sort.each do |x|
          arr << x.to_norm_line
        end
        ret = arr.join("")
      end
      @norm = ret
    end
    @norm
  end

  def to_norm_line
    line = group ? "#{group}." : ""
    line << name.to_s.tr("_", "-").upcase

    (params || {}).sort.each do |p|
      line << ";#{p.to_norm}"
    end

    line << ":#{value.to_norm}"

    line = Vobject::fold_line(line) << "\n"

    line
  end


  def to_hash
    ret = {}
    if multiple
      ret[prop_name] = []
      multiple.each do |c|
        ret[prop_name] = ret[prop_name] << c.to_hash[prop_name]
      end
    else
      ret = {prop_name => { value: value.to_hash } }
      ret[prop_name][:group] = group unless group.nil?
      if params
        ret[prop_name][:params] = {}
        params.each do |p|
          ret[prop_name][:params] = ret[prop_name][:params].merge p.to_hash
        end
      end
    end
    ret
  end

  private

  def name
    prop_name
  end

  def parse_value(value)
    parse_method = :"parse_#{value_type}_value"
    parse_method = respond_to?(parse_method, true) ? parse_method : :parse_text_value
    send(parse_method, value)
  end

  def parse_text_value(value)
    value
  end

  def value_type
    params ? params[0].value : default_value_type
  end

  def default_value_type
    "text"
  end

  def property_base_class
    Vobject::Property
  end

  def parameter_base_class
    Vobject::Parameter
  end

  def raise_invalid_initialization
    raise "vObject property initialization failed"
  end
end
