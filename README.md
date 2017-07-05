# Vobject

The main purpose of the gem is to parse vobject formatted text into a ruby
hash format. Currently there are two possiblities of vobjects, namely
iCalendar (https://tools.ietf.org/html/rfc5545) and vCard
(https://tools.ietf.org/html/rfc6350). There are only a few differences
between the iCalendar and vCard format. Only vCard supports grouping
feature, and currently vCard does not have any sub-object supported.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruby-vobject'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ruby-vobject

## Usage

Vobject.parse("<ics/vcf file>")

* Properties are hash keys; each property maps to a hash of a value (key `:value`),
and one or more parameters (key `:params`).
* The parameters of a property are themselves represented as a hash. Its keys are 
the parameter names; its values are the parameter values. If there are multiple values for
a parameter, the values are given as an array.
* If a property has multiple values, given on separate lines, they are represented
as an array of value hashes. Each value hash may have its own parameters.
* Components are themselves represented as hashes, from the component name to its properties.

Example:

A sample ics file (in spec/examples/example2.ics):

```
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//ABC Corporation//NONSGML My Product//EN
BEGIN:VTODO
DTSTAMP:19980130T134500Z
SEQUENCE:2
UID:uid4@example.com
ORGANIZER:mailto:unclesam@example.com
ATTENDEE;PARTSTAT=ACCEPTED:mailto:jqpublic@example.com
ATTENDEE;DELEGATED-TO="mailto:jdoe@example.com","mailto:j
 qpublic@example.com":mailto:jsmith@example.com
DUE:19980415T000000
STATUS:NEEDS-ACTION
SUMMARY:Submit Income Taxes
BEGIN:VALARM
ACTION:AUDIO
TRIGGER:19980403T120000Z
ATTACH;FMTTYPE=audio/basic:http://example.com/pub/audio-
 files/ssbanner.aud
REPEAT:4
DURATION:PT1H
END:VALARM
END:VTODO
END:VCALENDAR
```

Parse the ics file into Ruby hash format:

```ruby
require 'vobject'

ics = File.read "spec/examples/example2.ics"
Vobject.parse(ics)

=> {:VCALENDAR=>{:VERSION=>{:value=>"2.0"}, :PRODID=>{:value=>"-//ABC Corporation//NONSGML My Product//EN"}, :VTODO=>{:DTSTAMP=>{:value=>"19980130T134500Z"}, :SEQUENCE=>{:value=>"2"}, :UID=>{:value=>"uid4@example.com"}, :ORGANIZER=>{:value=>"mailto:unclesam@example.com"}, :ATTENDEE=>[{:value=>"mailto:jqpublic@example.com", :params=>{:PARTSTAT=>"ACCEPTED"}}, {:value=>"mailto:jsmith@example.com", :params=>{:"DELEGATED-TO"=>["mailto:jqpublic@example.com", "mailto:jdoe@example.com"]}}], :DUE=>{:value=>"19980415T000000"}, :STATUS=>{:value=>"NEEDS-ACTION"}, :SUMMARY=>{:value=>"Submit Income Taxes"}, :VALARM=>{:ACTION=>{:value=>"AUDIO"}, :TRIGGER=>{:value=>"19980403T120000Z"}, :ATTACH=>{:value=>"http://example.com/pub/audio-files/ssbanner.aud", :params=>{:FMTTYPE=>"audio/basic"}}, :REPEAT=>{:value=>"4"}, :DURATION=>{:value=>"PT1H"}}}}}
```

Running spec:
bundle exec rspec

## Implementation

This gem is implemented using (Rsec)[https://github.com/luikore/rsec], a very fast PEG grammar based on StringScanner.

## Development

Some really simple specs have been written. Please make sure they still
pass after migrating into the grammar parser approach. Also, some other
specs such as some special characters as stated in RFC 5545 and 6350
should be tested as well.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/riboseinc/ruby-vobject. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

