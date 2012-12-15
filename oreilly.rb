require 'rubygems'
require 'cgi'
require 'uri'
require 'mechanize'
require 'mechanize/progressbar'
require 'json'


def sanitize_filename(filename)
   fn = filename.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m
   fn.map! { |s| s.gsub /[^a-z0-9\-\'\"\&\_]+/i, ' ' }
  return fn.join '.'
end





puts "O'Reilly Downloader"
puts "-------------------\n"

# Fetch the user's input
print "Username: "
email = gets.chomp

print "Password: "
password = gets.chomp

print "\n"
print "Download directory (NO trailing slash) [~/Movies/O'Reilly]: "
directory = gets.chomp
directory = '~/Movies/O\'Reilly' if directory.empty?


print "\n"
# Ensure that the download directory exists and is writable...
path = File.expand_path directory

Dir.mkdir(path) unless File.directory? path

unless File.writable?(path)
  puts "Your download directory is unwritable!"
  exit 1
end

# Load the login page
print "\n"
puts "Loading O'Reilly..."

	agent = Mechanize.new
	page = agent.get 'https://members.oreilly.com/account/login'
		  
	# Log in to the site
	form = page.form_with :id => "std_login"
	
	form.email = email
	form.password = password
	
	page = agent.submit form, form.buttons.first
	page = page.link_with(:text => 'Your Products').click
	
	# Find every link to a product (screencast/video)
	links = page.links.find_all { |l| l.text =~ /Download Video/ }
	
	# Loop through each link and begin to download!
	links.each do |link|
	  page = link.click
	  	screencast_name = page.search('#title').text
	  	download_links = page.links.find_all { |l| l.href =~ /\.mp4$/ }
	  	download_links.each { |download| 
	    # use head verb to get header information without downloading file. need to do so because actual filename is not available in link
	    headers = agent.head download.href 
	    filename = headers.filename.gsub("\"",'')
	    
	    sanitized_filename = sanitize_filename(filename)
	    sanitized_screencast_name = sanitize_filename(screencast_name)
	    full_path = "#{path}/#{sanitized_screencast_name}/#{sanitized_filename}"
	 
		    unless File.exists?(full_path) || full_path.nil?
			    agent.progressbar(:single => true, :title => sanitized_filename) do
				agent.get(download.href).save("#{full_path}")
		    end
	   
	    end 
	    
	  	}
end

