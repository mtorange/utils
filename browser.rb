require 'net/http'
require 'net/https'
require 'parsedate'
require 'stringio'

def u_escape(string)
	string.gsub(/([^ a-zA-Z0-9_.-\/\:]+)/n) do
		'%' + $1.unpack('H2' * $1.size).join('%').upcase
	end.tr(' ', '+')
end

def u_unescape(string)
	string.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n) do
		[$1.delete('%')].pack('H*')
	end
end

def mk_query_string(form_data)
	str = ''
	form_data.each{ |k, v| 
		if '' != str
			str << "&"
		end
		str << u_escape(k)
		str << "="
		str << u_escape(v) 
	}
	return str
end
	


class Page
	def initialize( url)
		@uri = url
	end
	def merge(lnk)
		begin
			return u_unescape(URI.parse(@uri).merge!(u_escape(lnk)).to_s)
		rescue
			return ""
		end
	end
	def url()
		return @uri
	end
end

class Browser 
	def initialize()
		@cookie={
			#'name' => 'value',
		}
		@header={
			#'name' => 'value',
		}
		#@referer = nil
		@read_timeout = 50
		@user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_7) AppleWebKit/534.24 (KHTML, like Gecko) Chrome/11.0.696.68 Safari/534.24'
		#@user_agent = 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0)'
		#@user_agent = 'Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/534.24 (KHTML, like Gecko) Chrome/11.0.696.71 Safari/534.24'
		@proxy_host = nil
		@proxy_port = 80
		@dbg_indent_array = Array.new()
		@dbg_boundary='foobarBoundary'
		@dbg_enable = false
		@dbg_header_enable = false
	end

	def set_debug(enable)
		@dbg_enable = enable
	end
	def set_header_debug(enable)
		@dbg_header_enable = enable
	end

	def set_proxy(host, port)
		@proxy_host = host
		@proxy_port = port
	end
	def set_user_agent(ua)	
		@user_agent = ua
	end

	def add_header(n, v)
		#@header.update(n, v)
		@header[n] = v
	end

	def headers(u, cur_page)
		str = ''
		@cookie.each{ |k, a| 
			if
				#(nil == a['path'] || u.request_uri.match(/^#{a['path']}/)) &&
				#(nil == a['domain'] || u.host.match(/#{a['domain']}$/)) &&
				(nil == a['path'] || u.request_uri.start_with?(a['path'])) &&
				(nil == a['domain'] || u.host.end_with?(a['domain'])) &&
				("on" != a['secure'] || "https" == u.scheme)
				# TODO :  'expires' must be tested 

				str << "#{a['name']}=#{a['value']}; "
			end
		}

		rv = { 
			'User-Agent'=> @user_agent, 
			'Cache-Control' => 'max-age=0',
			'Accept' => 'application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5',
			'Accept-Language' => 'ko-KR,ko;q=0.8,en-US;q=0.6,en;q=0.4'
		}

		if nil != cur_page
			rv.update( { 'Referer' => cur_page.url })
		end
		if '' != str
			rv.update( { 'Cookie' => str } )
		end

		@header.each { |k, v|
			rv.update( {k => v} )
		}

		return rv
	end

	def query_cookie(name, domain, path)
		@cookie.each{ |k, a| 
			if
				(name == a['name']) &&
				(nil == a['path'] || path.start_with?(a['path'])) &&
				(nil == a['domain'] || domain.end_with?(a['domain'])) 
				# TODO :  'expires' must be tested 

				return a['value']
			end
		}
		return nil
	end

	def set_cookie(name, value, domain, path)
		map = {
			'name' => name,
			'value' => value,
			'domain' => domain,
			'path' => path
		}
		@cookie[ [map['name'], map['domain'], map['path']] ] = map
	end

	def update_cookie(u, r)
		cs = r.get_fields('set-cookie')
		if nil != cs 
			cs.each{ |set_cookie|
				i = 0
				## PK : name, domain, path
				map = {}
				set_cookie.split(';').each { |z|
					y = z.partition('=')
					if 0 == i 
						map['name'] = y[0].to_s
						map['value'] = y[2].to_s
					else
						if '' == y[2]
							y[2] = "on"
						end
						map[ y[0].strip.downcase ] = y[2].strip
					end
					i += 1
				}	
				if nil == map['domain']
					map['domain'] = u.host
				end
				if nil == map['path']
					p = u.path.rpartition('/')[0]
					if '' == p
						p = '/'
					end
					map['path'] =  p
					map['path-default'] = u.path + " ["+ p+ "]"
				end
				exp = map['expires']
				if nil != exp && (Time.gm(*ParseDate::parsedate(exp)) <=> Time.now()) < 0
					# do nothing..
				elsif nil != map['name']
					@cookie[ [map['name'], map['domain'], map['path']] ] = map
				end
				
			}
		end
	end

	def get_http_actor (url)
		u = URI.parse(url)

		http = nil
		if nil == @proxy_host 
			http = Net::HTTP.new(u.host, u.port)
		else
			http = Net::HTTP.Proxy(@proxy_host, @proxy_port).new(u.host, u.port)
		end

		if "https" == u.scheme
			http.use_ssl= true
		end
		http.read_timeout = @read_timeout
		return http, u
	end

	def dbg_print_log(log)
		if @dbg_enable
			print "DEBUG: "
			print log
			$stdout.flush
		end
	end

	def dbg_print_header_log(hdrs)
		if @dbg_header_enable
			hdrs.each { |n, v|
				print "debug:     #{n}: #{v}\n"
			}
		end
	end

	def dbg_dump_response( url, r, hdrs)
		## for debugging
=begin
		File.open("dbg/da"+@dbg_idx.to_s+".log", "w") { |f|  
			f.write(url)
			f.write("\n======================\n")
			hdrs.each { |k, v| f.write(k + ": " + v + "\n") }
			f.write("\n======================\n")
			r.each_header { |k,v|
				r.get_fields(k).each{ |vv| f.write(k + ": " + vv + "\n") }
			}
			f.write("\n======================\n")
			f.write(r.body) 
		}
		File.open("dbg/db"+@dbg_idx.to_s+".html", "w") { |f|  
			f.write(r.body) 
		}
		@dbg_idx += 1
=end
	end

	def get_page(url, cur_page)
		dbg_print_log("#{@dbg_indent_array.to_s}get_page(#{url})\n")

		h, u = get_http_actor(url)
		hdrs = headers(u, cur_page)

		dbg_print_header_log(hdrs)
		r = h.get2(u.request_uri, hdrs)
		update_cookie(u, r)
		dbg_dump_response(url, r, hdrs)
		return r, Page::new(url)
	end


	# post_data = string
	def post_page(url, cur_page, post_data, content_type = "application/x-www-form-urlencoded")
		dbg_print_log("post_page(#{url})\n")

		h, u = get_http_actor(url)

		hdrs = headers(u, cur_page)
		hdrs.update( {"Content-Type" => content_type} )

		dbg_print_header_log(hdrs)
		r = h.post(u.request_uri, post_data, hdrs)
		update_cookie(u, r)
		dbg_dump_response(url, r, hdrs)
		return r, Page::new(url)
	end

	# form_data = hash map
	def post_form(url, cur_page, form_data)
		dbg_print_log("post_form(#{url})\n")

		h, u = get_http_actor(url)

		hdrs = headers(u, cur_page)
		dbg_print_header_log(hdrs)
		req = Net::HTTP::Post.new(u.path, hdrs)
		req.set_form_data(form_data)
		r = h.request(req)
		update_cookie(u, r)
		dbg_dump_response(url, r, hdrs)
		return r, Page::new(url)
	end

	def post_file_data(url, cur_page, form_data, f_name, f_file, f_mime, f_data)
		_nl = "\r\n"
		dbg_print_log("post_file_data(#{url})\n")

		h, u = get_http_actor(url)

		out = StringIO.new
		boundary = "---Browser-rb-" + rand(999999999).to_s+rand(9999999999).to_s;
		fsize = f_data.size
		out << "--" + boundary
		out << _nl
		out << "Content-Disposition: form-data; name=\"#{f_name}\"; filename=\"#{File.basename(f_file)}\"#{_nl}"
		out << "Content-Type: #{f_mime}#{_nl}"
		out << "Content-Length: #{fsize.to_s}#{_nl}"
		out << "Content-Transfer-Encoding: binary#{_nl}"
		out << _nl
		out << f_data
		out << _nl
		form_data.each { |n, v|
			out << "--" +boundary
			out << _nl
			out << "Content-Disposition: form-data; name=\"#{n}\"#{_nl}"
			out << _nl
			out << v
			out << _nl
		}
		out << "--" + boundary + "--"
		out << _nl

		hdrs = headers(u, cur_page)
		hdrs["Content-Type"] = "multipart/form-data; boundary="+boundary
		hdrs["Content-Length"] = out.size.to_s

		dbg_print_header_log(hdrs)
		r = h.post(u.request_uri, out.string, hdrs)
		update_cookie(u, r)
		dbg_dump_response(url, r, hdrs)
		return r, Page::new(url)
	end

	def post_file(url, cur_page, form_data, f_name, f_file, f_mime )
		return post_file_data(url, cur_page, form_data, f_name, f_file, f_mime, IO.read(f_file))
	end


	def chk_redirect(response, cur_page, limit = 10)
		if limit == 0 
			raise ArgumentError, 'HTTP redirect too deep' 
		end

		case response
		when Net::HTTPSuccess 
			return response, cur_page
		when Net::HTTPRedirection 
			@dbg_indent_array.push('      ')
			dbg_print_log("#{@dbg_indent_array.to_s}>>> redirected >>>>>> \n")
			r, page = get_page(response['location'], cur_page)
			r, page = chk_redirect(r, page, limit-1)
			@dbg_indent_array.pop
			return r, page
		else
			return response, cur_page
		end
	end

	def get_page_r(url, cur_page)
		r, page = get_page(url, cur_page)
		return chk_redirect(r, page)
	end

	def post_page_r(url, cur_page, post_data, content_type = "application/x-www-form-urlencoded")
		r, page = post_page(url, cur_page, post_data, content_type)
		return chk_redirect(r, page)
	end

	def post_form_r(url, cur_page, form_data)
		r, page = post_form(url, cur_page, form_data)
		return chk_redirect(r, page)
	end
	def post_file_r(url, cur_page, form_data, f_name, f_file, f_mime )
		r, page = post_file(url, cur_page, form_data, f_name, f_file, f_mime)
		return chk_redirect(r, page)
	end
	def post_file_data_r(url, cur_page, form_data, f_name, f_file, f_mime, f_data )
		r, page = post_file_data(url, cur_page, form_data, f_name, f_file, f_mime, f_data)
		return chk_redirect(r, page)
	end
end




