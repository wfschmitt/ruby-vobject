require "rsec"
require "set"
require "uri"
require "date"
require "tzinfo"
include Rsec::Helpers
require_relative "../c"
require_relative "../error"
require 'vobject'

module Vobject
 class Typegrammars

    class << self


  # property value types, each defining their own parser
  def recur
    freq	= /SECONDLY/i.r | /MINUTELY/i.r | /HOURLY/i.r | /DAILY/i.r |
	    		/WEEKLY/i.r | /MONTHLY/i.r | /YEARLY/i.r
    enddate 	= C::DATE_TIME | C::DATE
    seconds 	= /[0-9]{1,2}/.r
    byseclist 	= seq(seconds, ',', lazy{byseclist}) {|s, _, l|
	    		[s, l].flatten
	    	} | seconds.map {|s| s}
    minutes 	= /[0-9]{1,2}/.r
    byminlist 	= seq(minutes, ',', lazy{byminlist}) {|m, _, l|
	    		[m, l].flatten
		} | minutes.map {|m| m}
    hours 	= /[0-9]{1,2}/.r
    byhrlist 	= seq(hours, ',', lazy{byhrlist}) {|h, _, l|
	    		[h, l].flatten
		} | hours.map {|h| h}
    ordwk 	= /[0-9]{1,2}/.r
    weekday 	= /SU/i.r | /MO/i.r | /TU/i.r | /WE/i.r | /TH/i.r | /FR/i.r | /SA/i.r
    weekdaynum1	= seq(C::SIGN._?, ordwk) {|s, o|
	    		h = {:ordwk => o}
			h[:sign] = s[0] unless s.empty?
			h
	    	}
    weekdaynum 	= seq(weekdaynum1._?, weekday) {|a, b|
	    		h = {:weekday => b}
			h.merge a[0] unless a.empty?
			h
	    	}
    bywdaylist 	= seq(weekdaynum, ',', lazy{bywdaylist}) {|w, _, l|
	    		[w, l].flatten
		} | weekdaynum.map {|w| w} 
    ordmoday 	= /[0-9]{1,2}/.r
    monthdaynum = seq(C::SIGN._?, ordmoday) {|s, o|
	    		h = {:ordmoday => o}
			h[:sign] = s[0] unless s.empty?
			h
	    	}
    bymodaylist = seq(monthdaynum, ',', lazy{bymodaylist}) {|m, _, l|
	    		[m, l].flatten
		} | monthdaynum.map {|m| m}
    ordyrday 	= /[0-9]{1,3}/.r
    yeardaynum	= seq(C::SIGN._?, ordyrday) {|s, o|
	    		h = {:ordyrday => o}
			h[:sign] = s[0] unless s.empty?
			h
	    	}
    byyrdaylist = seq(yeardaynum, ',', lazy{byyrdaylist}) {|y, _, l|
	    		[y, l].flatten
		} | yeardaynum.map {|y| y}
    weeknum 	= seq(C::SIGN._?, ordwk) {|s, o|
	    		h = {:ordwk => o}
			h[:sign] = s[0] unless s.empty?
			h
	    	}
    bywknolist 	= seq(weeknum, ',', lazy{bywknolist}) {|w, _, l|
	    		[w, l].flatten
		} | weeknum.map {|w| w}
    #monthnum 	= /[0-9]{1,2}/.r
    # RFC 7529 add leap month indicator
    monthnum 	= /[0-9]{1,2}L?/i.r
    bymolist 	= seq(monthnum, ',', lazy{bymolist}) {|m, _, l|
	    		[m, l].flatten
		} | monthnum.map {|m| m}
    setposday	= yeardaynum
    bysplist 	= seq(setposday, ',', lazy{bysplist}) {|s, _, l|
	    		[s, l].flatten
		} | setposday.map {|s| s}
    # http://www.unicode.org/repos/cldr/tags/latest/common/bcp47/calendar.xml
    rscale	= C::XNAME | /buddhist/i.r | /chinese/i.r | /coptic/i.r | /dangi/i.r |
	    	/ethioaa/i.r | /ethiopic-amete-alem/i.r | /ethiopic/i.r |
		/gregory/i.r | /hebrew/i.r | /indian/i.r | /islamic/i.r |
		/islamic-umalqura/i.r | /islamic-tbla/i.r | /islamic-civil/i.r |
		/islamic-rgsa/i.r | /iso8601/i.r | /japanese/i.r | /persian/i.r |
		/roc/i.r | /islamicc/i.r | /gregorian/i.r
    skip	= /OMIT/i.r | /BACKWARD/i.r | /FORWARD/i.r
    recur_rule_part = 	seq(/FREQ/i.r, '=', freq) {|k, _, v| {:freq => v} } |
	    seq(/UNTIL/i.r, '=', enddate) {|k, _, v| {:until => v} } |
	    seq(/COUNT/i.r, '=', /[0-9]+/i.r) {|k, _, v| {:count => v} } |
	    seq(/INTERVAL/i.r, '=', /[0-9]+/i.r) {|k, _, v| {:interval => v} } |
	    seq(/BYSECOND/i.r, '=', byseclist) {|k, _, v| {:bysecond => v} } |
	    seq(/BYMINUTE/i.r, '=', byminlist) {|k, _, v| {:byminute => v} } |
	    seq(/BYHOUR/i.r, '=', byhrlist) {|k, _, v| {:byhour => v} } |
	    seq(/BYDAY/i.r, '=', bywdaylist) {|k, _, v| {:byday => v} } |
	    seq(/BYMONTHDAY/i.r, '=', bymodaylist) {|k, _, v| {:bymonthday => v} } |
	    seq(/BYYEARDAY/i.r, '=', byyrdaylist) {|k, _, v| {:byyearday => v} } |
	    seq(/BYWEEKNO/i.r, '=', bywknolist)  {|k, _, v| {:byweekno => v} } |
	    seq(/BYMONTH/i.r, '=', bymolist)  {|k, _, v| {:bymonth => v} } |
	    seq(/BYSETPOS/i.r, '=', bysplist)  {|k, _, v| {:bysetpos => v} } |
	    seq(/WKST/i.r, '=', weekday)  {|k, _, v| {:wkst => v} } |
	    # RFC 7529
	    seq(/RSCALE/i.r, '=', rscale)  {|k, _, v| {:rscale => v} } | 
	    seq(/SKIP/i.r, '=', skip)  {|k, _, v| {:skip => v} } 
    recur 	= seq(recur_rule_part, ';', lazy{recur}) {|h, _, r| h.merge r } | 
	    	recur_rule_part
    recur.eof
  end

  def integer  
    integer 	= prim(:int32)
    integer.eof
  end
  
  def percent_complete  
    integer 	= prim(:int32) {|a|
	    		(a >= 0 and a <= 100) ? a :  {:error => 'Percentage outside of range 0..100'}
	    	}
    integer.eof
  end
  
  def priority  
    integer 	= prim(:int32) {|a|
	    		(a >= 0 and a <= 9) ? a :  {:error => 'Percentage outside of range 0..100'}
	    	}
    integer.eof
  end

  def floatT
	 floatT = prim(:double)
	 floatT.eof
  end

  def timeT
	  timeT = C::TIME
	  timeT.eof
  end
  
  def geovalue
    float 	    = prim(:double)
    # TODO confirm that Rsec can do signs!
    geovalue	= seq(float, ';', float) {|a, _, b|
	     ( a <= 180.0 and a >= -180.0 and b <= 180 and b > -180 ) ? {:lat => a, :long => b} :
			{:error => 'Latitude/Longitude outside of range -180..180'}
    }
    geovalue.eof
  end

  def calscalevalue
    calscalevalue = /GREGORIAN/i.r
    calscalevalue.eof
  end

  def ianaToken
    ianaToken 	= C::IANATOKEN 
    ianaToken.eof
  end 

  def versionvalue
     versionvalue = 
                    seq(prim(:double), ';', prim(:double)) {|x, _, y| [x, y] } |
	     		'2.0'.r | prim(:double) 
     versionvalue.eof
  end

  def binary
	binary	= seq(/[a-zA-Z0-9+\/]*/.r, /={0,2}/.r) {|b, q|
				( (b.length + q.length) % 4 == 0 ) ? b + q : {:error => 'Malformed binary coding'}
		}
	binary.eof
  end

  def uri
	uri         = /\S+/.r.map {|s|
	                  	s =~ URI::regexp ? s : {:error => 'Invalid URI'}
			 }
	uri.eof
  end

  def textT
    text	= C::TEXT.map {|t| unescape t }
    text.eof
  end

  def textlist
    textlist	=  
	    	seq(C::TEXT, ','.r, lazy{textlist}) { |a, _, b| [unescape(a), b].flatten }  | 
		C::TEXT.map {|t| [unescape(t)]}
    textlist.eof
  end

  def request_statusvalue
	    @req_status = Set.new %w{2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 2.10 2.11 3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 3.10 3.11 3.12 3.13 3.14 4.0 5.0 5.1 5.2 5.3}
    extdata = seq(';'.r, C::TEXT) {|_, t| t}
    request_statusvalue = seq(/[0-9](\.[0-9]){1,2}/.r, ';'.r, C::TEXT, extdata._?) {|n, _, t1, t2|
			    return {:error => "Invalid request status #{n}"} unless @req_status.include?(n) #RFC 5546   			
                            hash = {:statcode => n, :statdesc => t1}
                            hash[:extdata] = t2[0] unless t2.empty?
                            hash
                        }
    request_statusvalue.eof
  end

  def classvalue
	classvalue = /PUBLIC/i.r | /PRIVATE/i.r | /CONFIDENTIAL/i.r | C::XNAME | C::IANATOKEN
	classvalue.eof
  end

  def eventstatus
	  eventstatus	= /TENTATIVE/i.r | /CONFIRMED/i.r | /CANCELLED/i.r
	  eventstatus.eof
  end

  def todostatus
	  todostatus	= /NEEDS-ACTION/i.r | /COMPLETED/i.r | /IN-PROCESS/i.r | /CANCELLED/i.r
	  todostatus.eof
  end

  def journalstatus
	  journalstatus	= /DRAFT/i.r | /FINAL/i.r | /CANCELLED/i.r
	  journalstatus.eof
  end

  def dateT
     date = C::DATE
     date.eof
  end

  def datelist
	 datelist   = 
		 seq(C::DATE, ",".r, lazy{datelist}) {|d, _, l|
	                [d, l].flatten
	            }  |
		 C::DATE.map {|d| [d] } 
     	datelist.eof
  end

  def date_timeT
     C::DATE_TIME.eof
  end

  def date_timelist
	 date_timelist   = 
			seq(C::DATE_TIME, ",".r, lazy{date_timelist}) {|d, _, l|
	                [d, l].flatten
	            } |
		 	C::DATE_TIME.map {|d| [d] }  
     date_timelist.eof
  end

  def date_time_utcT
     date_time_utc	= C::DATE_TIME_UTC
     date_time_utc.eof
  end
  
  def date_time_utclist
	 date_time_utclist   = seq(C::DATE_TIME_UTC, ",".r, lazy{date_time_utclist}) {|d, _, l|
	                [d, l].flatten
	            } |
		 C::DATE_TIME_UTC.map {|d| [d] } 
     date_time_utclist.eof
  end

  def durationT
    duration = C::DURATION
    duration.eof
  end
  
  def periodlist
    period_explicit = seq(C::DATE_TIME, "/".r, C::DATE_TIME) {|s, _, e|
                        {:start => s, :end => e}
                    }
    period_start    = seq(C::DATE_TIME, "/".r, C::DURATION) {|s, _, d|
                        {:start => s, :duration => d}
                    }
    period 	        = period_explicit | period_start
    periodlist      = seq(period, ",".r, lazy{periodlist}) {|p, _, l|
                        [p, l].flatten
                    } |
	    		period.map {|p| [p] } 
    periodlist.eof
  end
  
  def transpvalue
	  transpvalue	= /OPAQUE/i.r | /TRANSPARENT/i.r
	  transpvalue.eof
  end

  def utc_offset
    utc_offset 	= seq(C::SIGN, /[0-9]{2}/.r, /[0-9]{2}/.r, /[0-9]{2}/.r._?) {|sign, h, m, sec|
	    		hash = {:sign => sign, :hr => h, :min => m }
			hash[:sec] = sec[0] unless sec.empty?
			hash
    		}
    utc_offset.eof
  end

  def actionvalue
	  actionvalue	= /AUDIO/i.r | /DISPLAY/i.r | /EMAIL/i.r | C::IANATOKEN | C::XNAME
	  actionvalue.eof
  end

  def boolean
	  boolean = C::BOOLEAN
	  boolean.eof
  end

  # RFC 5546
  def methodvalue
	  methodvalue 	= /PUBLISH/i.r | /REQUEST/i.r | /REPLY/i.r | /ADD/i.r | /CANCEL/i.r | /REFRESH/i.r | 
		  	/COUNTER/i.r | /DECLINECOUNTER/i.r
	  methodvalue.eof
  end

  # RFC 7953
  def busytype
	  busytype = /BUSY-UNAVAILABLE/i.r | /BUSY-TENTATIVE/i.r | /BUSY/i.r |  C::IANATOKEN | C::XNAME
	  busytype.eof
  end

  # https://www.w3.org/TR/2011/REC-css3-color-20110607/#svg-color
  def color
	  color = C::COLOR
	  color.eof
  end


  # text escapes: \\ \; \, \N \n
  def unescape(x)
	  x.gsub(/\\\\/, '\\').gsub(/\\;/, ';').gsub(/\\,/, ',').gsub(/\\[Nn]/, "\n")
  end
  
  def registered_propname
    registered_propname = C::NAME
    registered_propname.eof
  end
  
  def is_registered_propname?(x)
    p = registered_propname.parse(x)
    return not(Rsec::INVALID[p])
  end 
  
  # Ensure each property belongs to a legal component
  def property_parent(key, component, value, ctx1)
    if not (key =~ /^x/i) and is_registered_propname?(key.to_s)
        case component
        when :EVENT
            case key
            when :DTSTAMP, :UID, :DTSTART, :CLASS, :CREATED, :DESCRIPTION,
            :GEO, :LAST_MOD, :LOCATION, :ORGANIZER, :PRIORITY, :SEQUENCE, :STATUS,
            :SUMMARY, :TRANSP, :URL, :RECURRENCE_ID, :RRULE, :DTEND, :DURATION,
            :ATTACH, :ATTENDEE, :CATEGORIES, :COMMENT, :CONTACT, :EXDATE,
            :RSTATUS, :RELATED, :RESOURCES, :RDATE, :COLOR, :CONFERENCE, :IMAGE
            else
                        raise ctx1.report_error "Invalid property #{key} specified for #{component}", 'source'
            end
        when :TODO
            case key
            when :DTSTAMP, :UID, :DTSTART, :CLASS, :CREATED, :DESCRIPTION,
            :GEO, :LAST_MOD, :LOCATION, :ORGANIZER, :PRIORITY, :PERCENT_COMPLETED, :SEQUENCE, :STATUS,
            :SUMMARY, :URL, :RECURRENCE_ID, :RRULE, :DUE, :DURATION,
            :ATTACH, :ATTENDEE, :CATEGORIES, :COMMENT, :CONTACT, :EXDATE,
            :RSTATUS, :RELATED, :RESOURCES, :RDATE, :COLOR, :CONFERENCE, :IMAGE
            else
                        raise ctx1.report_error "Invalid property #{key} specified for #{component}", 'source'
            end
        when :JOURNAL
            case key
            when :DTSTAMP, :UID, :DTSTART, :CLASS, :CREATED, :DESCRIPTION,
            :LAST_MOD, :ORGANIZER, :RECURRENCE_ID, :SEQUENCE, :STATUS,
            :SUMMARY, :URL, :RRULE, 
            :ATTACH, :ATTENDEE, :CATEGORIES, :COMMENT, :CONTACT, :EXDATE,
            :RSTATUS, :RELATED,  :RDATE, :COLOR, :IMAGE
            else
                        raise ctx1.report_error "Invalid property #{key} specified for #{component}", 'source'
            end
        when :FREEBUSY
            case key
            when :DTSTAMP, :UID, :CONTACT, :DTSTART, :DTEND, :ORGANIZER, :URL,
            :ATTENDEE, :COMMENT, :FREEBUSY, :RSTATUS
            else
                        raise ctx1.report_error "Invalid property #{key} specified for #{component}", 'source'
            end
        when :TIMEZONE
            case key
            when :TZID, :LAST_MODIFIED, :TZURL
            else
                        raise ctx1.report_error "Invalid property #{key} specified for #{component}", 'source'
            end
        when :DAYLIGHT, :STANDARD
            case key
            when :DTSTART, :TZOFFSETTO, :TZOFFSETFROM, :RRULE,
            :COMMENT, :RDATE, :TZNAME
            else
                        raise ctx1.report_error "Invalid property #{key} specified for #{component}", 'source'
            end
        when :ALARM
            case key
            when :ACTION, :TRIGGER, :DURATION, :REPEAT, :ATTACH, :DESCRIPTION,
            :SUMMARY, :ATTENDEE
            else
                        raise ctx1.report_error "Invalid property #{key} specified for #{component}", 'source'
            end
        when :VAVAILABILITY
            case key
            when :DTSTAMP, :UID, :BUSYTYPE, :CLASS, :CREATED, :DESCRIPTION,
            :DTSTART, :LAST_MODIFIED, :LOCATION, :ORGANIZER, :PRIORITY, :SEQUENCE,
            :SUMMARY, :URL, :DTEND, :DURATION, :CATEGORIES, :COMMENT, :CONTACT
            else
                        raise ctx1.report_error "Invalid property #{key} specified for #{component}", 'source'
            end
        when :AVAILABLE
            case key
            when :DTSTAMP, :DTSTART, :UID, :DTEND, :DURATION, :CREATED,
            :DESCRIPTION, :LAST_MODIFIED, :LOCATION, :RECURRENCE_ID, :RRULE,
            :SUMMARY, :CATEGORIES, :COMMENT, :CONTACT, :EXDATE, :RDATE
            else
                        raise ctx1.report_error "Invalid property #{key} specified for #{component}", 'source'
            end
        end
    end    
  end

  # Enforce type restrictions on values of particular properties.
  # If successful, return typed interpretation of string
  def typematch(key, params, component, value, ctx)
    property_parent(key, component, value, ctx)
    ctx1 = Rsec::ParseContext.new value, 'source'
    case key
    when :CALSCALE
	    ret = calscalevalue._parse ctx1
    when :METHOD
	    ret = methodvalue._parse ctx1
    when :VERSION
	    ret = versionvalue._parse ctx1
    when :ATTACH
	    if params[:VALUE] == 'BINARY'
		    ret = binary._parse ctx1
	    else
		    ret = uri._parse ctx1
	    end
    when :IMAGE
        raise ctx1.report_error "No VALUE parameter specified for property #{key}", 'source' if params.empty?
        raise ctx1.report_error "No VALUE parameter specified for property #{key}", 'source' unless params[:VALUE]
	    if params[:VALUE] == 'BINARY'
		raise ctx1.report_error "No ENCODING parameter specified for property #{key}", 'source' unless params[:ENCODING]
		raise ctx1.report_error "Incorrect ENCODING parameter specified for property #{key}", 'source' unless params[:ENCODING] == 'BASE64'
		    ret = binary._parse ctx1
	    elsif params[:VALUE] == 'URI'
		    ret = uri._parse ctx1
	    else
	raise ctx1.report_error "Incorrect VALUE parameter specified for property #{key}", 'source' 
	    end
    when :CATEGORIES, :RESOURCES
	    ret = textlist._parse ctx1
    when :CLASS
	    ret = classvalue._parse ctx1
    when :COMMENT, :DESCRIPTION, :LOCATION, :SUMMARY, :TZID, :TZNAME, :CONTACT, :RELATED_TO, :UID, :PRODID, :NAME
	    ret = textT._parse ctx1
    when :GEO
	    ret = geovalue._parse ctx1
    when :PERCENT_COMPLETE
	    ret = percent_complete._parse ctx1
    when :PRIORITY
	    ret = priority._parse ctx1
    when :STATUS
	    case component 
	    when :EVENT
		    ret = eventstatus._parse ctx1
	    when :TODO
		    ret = todostatus._parse ctx1
	    when :JOURNAL
		    ret = journalstatus._parse ctx1
	    else
		    ret = textT._parse ctx1
	    end
    when :COMPLETED, :CREATED, :DTSTAMP, :LAST_MODIFIED
	    ret = date_time_utcT._parse ctx1
    when :DTEND, :DTSTART, :DUE, :RECURRENCE_ID
	    if (key == :DTEND or key == :DTSTART) and (component == :VAVAILABILITY or component == :AVAILABLE)
	    		ret = date_timeT._parse ctx1
	    elsif params and params[:VALUE] == 'DATE'
	    	ret = dateT._parse ctx1
	    else
		if component == :FREEBUSY
	    		ret = date_time_utcT._parse ctx1
		else
			if params and params[:TZID]
				if component == :STANDARD or component == :DAYLIGHT
					raise ctx1.report_error "Specified TZID within property #{key} in #{component}", 'source'
				end
				begin
					tz = TZInfo::Timezone.get(params[:TZID])
	    				ret = date_time_utcT._parse ctx1
					ret = tz.utc_to_local(ret)
				rescue
					# undefined timezone
	    				ret = date_time_utcT._parse ctx1
				end
			else 
	    			ret = date_timeT._parse ctx1
			end
		end
	    end
    when :EXDATE
	    if params and params[:VALUE] == 'DATE'
	    	ret = datelist._parse ctx1
	    else
			if params and params[:TZID]
				if component == :STANDARD or component == :DAYLIGHT
					raise ctx1.report_error "Specified TZID within property #{key} in #{component}", 'source'
				end
				tz = TZInfo::Timezone.get(params[:TZID])
	    			ret = date_time_utclist._parse ctx1
				ret = ret.map {|x| tz.utc_to_local(x) }
			else 
	    			ret = date_timelist._parse ctx1
			end
		end
    when :RDATE
	    if params and params[:VALUE] == 'DATE'
	    	ret = datelist._parse ctx1
	    elsif params and params[:VALUE] == 'PERIOD'
	    	ret = periodlist._parse ctx1
	    else
			if params and params[:TZID]
				if component == :STANDARD or component == :DAYLIGHT
					raise ctx1.report_error "Specified TZID within property #{key} in #{component}", 'source'
				end
				tz = TZInfo::Timezone.get(params[:TZID])
	    			ret = date_time_utclist._parse ctx1
				ret = ret.map {|x| tz.utc_to_local(x) }
			else 
	    			ret = date_timelist._parse ctx1
			end
		end
    when :TRIGGER
	    if params and params[:VALUE] == 'DATE-TIME' or /^\d{8}T/.match(value)
	        if params and params[:RELATED]
				raise ctx1.report_error "Specified RELATED within property #{key} as date-time", 'source'	        
			end
	    	ret = date_time_utcT._parse ctx1
	    else
	    	ret = durationT._parse ctx1
		end
    when :FREEBUSY
	    ret = periodlist._parse ctx1
    when :TRANSP
	    ret = transpvalue._parse ctx1
    when :TZOFFSETFROM, :TZOFFSETTO
	    ret = utc_offset._parse ctx1
	when :TZURI, :URL, :SOURCE, :CONFERENCE
	    if key == :CONFERENCE
		    raise ctx1.report_error "Missing URI VALUE parameter" if params.empty?
		    raise ctx1.report_error "Missing URI VALUE parameter" if !params[:VALUE]
		raise ctx1.report_error "Type mismatch of VALUE parameter #{params[:VALUE]} for property #{key}" if params[:VALUE]  != 'URI'
	    end
	    ret = uri._parse ctx1
	when :ATTENDEE, :ORGANIZER
	    ret = uri._parse ctx1
	when :RRULE
	    ret = recur._parse ctx1
	when :ACTION
	    ret = actionvalue._parse ctx1
	when :REPEAT, :SEQUENCE
	    ret = integer._parse ctx1
	when :REQUEST_STATUS
	    ret = request_statusvalue._parse ctx1
	# RFC 7953
	when :BUSYTYPE
		ret = busytype._parse ctx1
	# RFC 7986
	when :REFRESH_INTERVAL
		raise ctx1.report_error "Missing VALUE parameter for property #{key}" if params.empty?
		raise ctx1.report_error "Missing VALUE parameter for property #{key}" if !params[:VALUE] 
		raise ctx1.report_error "Type mismatch of VALUE parameter #{params[:VALUE]} for property #{key}" if params[:VALUE]  != 'DURATION'
		ret = durationT._parse ctx1
	# RFC 7986
	when :COLOR
		ret = color._parse ctx1
    else
	    if params and params[:VALUE]
		case params[:VALUE]
		when "BOOLEAN"
			ret = boolean._parse ctx1
		when "BINARY"
			ret = binary._parse ctx1
		when "CAL-ADDRESS"
			ret = uri._parse ctx1
		when "DATE-TIME"
			ret = date_timeT._parse ctx1
		when "DATE"
			ret = dateT._parse ctx1
		when "DURATION"
			ret = durationT._parse ctx1
		when "FLOAT"
			ret = floatT._parse ctx1
		when "INTEGER"
			ret = integer._parse ctx1
		when "PERIOD"
			ret = period._parse ctx1
		when "RECUR"
			ret = recur._parse ctx1
		when "TEXT"
			ret = textT._parse ctx1
		when "TIME"
			ret = timeT._parse ctx1
		when "URI"
			ret = uri._parse ctx1
		when "UTC-OFFSET"
			ret = utc_offset._parse ctx1
		end
	    else 
	        ret = value
	    end
    end
    if ret.kind_of?(Hash) and ret[:error]
	raise  "#{ret[:error]} for property #{key}, value #{value}"
    end
    if Rsec::INVALID[ret] 
        raise "Type mismatch for property #{key}, value #{value}"
    end
    Rsec::Fail.reset
    return ret
  end
  
  
  



private

   def parse_err(msg, ctx)
	          raise ctx.report_error msg, 'source'
   end

  end
end
end