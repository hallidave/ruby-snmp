system "rake test"
exit if $? != 0

RELEASE="1.0.1"
TAG_CMD="svn copy svn+ssh://davehal@rubyforge.org/var/svn/snmplib/branches/branch-0.6.0 svn+ssh://davehal@rubyforge.org/var/svn/snmplib/tags/release-#{RELEASE} -m 'Tagging release #{RELEASE}'"

def check_svn_up
  puts "Checking svn updated"
  out = `svn up`
  unless out =~ /At revision \d+\./
    puts "svn up failed:"
    puts out
    exit(1)
  end
end

def check_svn_st
  puts "Checking svn committed"
  out = `svn st`
  out.each_line do |line|
    unless line =~ /^\?/
      puts "svn st failed:"
      puts out
      exit(1)
    end
  end
end

check_svn_up
check_svn_st

$VERBOSE=1
system TAG_CMD
