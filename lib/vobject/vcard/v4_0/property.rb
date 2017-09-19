require "vobject/property"

module Vcard::V4_0

  class Property < Vobject::Property

  end

  def parameter_base_class
    version_class.const_get(:Parameter)
  end

  def property_base_class
    version_class.const_get(:Property)
  end


  def version_class
    Vcard::V4_0
  end


end
