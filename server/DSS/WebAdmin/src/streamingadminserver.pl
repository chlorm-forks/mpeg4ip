#!/usr/bin/perl
# A very simple perl web server used by Streaming Admin Server

#---------------------------------------------------------
# Copyright (c) Jamie Cameron
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of the developer nor the names of contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE DEVELOPER ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE DEVELOPER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
# ---------------------------------------------------------

# Require needed libraries
package streamingadminserver;
use Socket;
use POSIX;
use Sys::Hostname;

# Get streamingadminserver's perl path and location
$streamingadminserver_path = $0;
open(SOURCE, $streamingadminserver_path);
<SOURCE> =~ /^#!(\S+)/; $perl_path = $1;
close(SOURCE);
@streamingadminserver_argv = @ARGV;

if($^O eq "MSWin32") {
	$defaultConfigPath = "C:/ProgramFiles/Darwin Streaming Server/treamingadminserver.conf";
}
else {
	$defaultConfigPath = "/etc/streaming/streamingadminserver.conf";
}

# Find and read config file
if (@ARGV != 1) {
    $conf = $defaultConfigPath;
}
else {
	if($^O eq "MSWin32") {
    	$conf = $ARGV[0];
	}
	else {
    	if ($ARGV[0] =~ /^\//) {
			$conf = $ARGV[0];
   	}
    	else {
			chop($pwd = `pwd`);
			$conf = "$pwd/$ARGV[0]";
    	}
	}
}

if(!open(CONF, $conf)) {
	if($conf ne $defaultConfigPath) {
		die "Failed to open config file $conf : $!";
	}
} else {
	while(<CONF>) {
	    chop;
	    if (/^#/ || !/\S/) { 
			next; 
	    }
	    /^([^=]+)=(.*)$/;
	    $name = $1; $val = $2;
	    $name =~ s/^\s+//g; $name =~ s/\s+$//g;
	    $val =~ s/^\s+//g; $val =~ s/\s+$//g;
	    $config{$name} = $val;
	}
	close(CONF);
}

# Check vital config options
if($^O eq "darwin") {
	%vital = ("port", 1220,
	  "root", "/Library/QuickTimeStreaming/AdminHtml",
	  "server", "QTSS 3.0 Admin Server/1.0",
	  "index_docs", "index.html index.htm index.cgi",
	  "addtype_html", "text/html",
	  "addtype_htm", "text/html",
	  "addtype_txt", "text/plain",
	  "addtype_gif", "image/gif",
	  "addtype_jpg", "image/jpeg",
	  "addtype_jpeg", "image/jpeg",
	  "addtype_cgi", "internal/cgi",
	  "realm", "QTSS Admin Server",
	  "qtssIPAddress", "localhost",
	  "qtssPort", "554",
	  "qtssName", "/usr/sbin/QuickTimeStreamingServer",
	  "logfile", "/Library/QuickTimeStreaming/Logs/streamingadminserver.log",
	  "log", "1",
	  "logclear", "0",
	  "logtime", "168"  
	  );
}
elsif($^O eq "MSWin32") {
	%vital = ("port", 1220,
	  "root", "C:/Program Files/Darwin Streaming Server/AdminHtml",
	  "server", "QTSS 3.0 Admin Server/1.0",
	  "index_docs", "index.html index.htm index.cgi",
	  "addtype_html", "text/html",
          "addtype_htm", "text/html",
	  "addtype_txt", "text/plain",
	  "addtype_gif", "image/gif",
	  "addtype_jpg", "image/jpeg",
	  "addtype_jpeg", "image/jpeg",
	  "addtype_cgi", "internal/cgi",
	  "realm", "QTSS Admin Server",
	  "qtssIPAddress", "localhost",
	  "qtssPort", "554",
	  "qtssName", "C:/Program Files/Darwin Streaming Server/DarwinStreamingServer.exe",
	  "logfile", "C:/Program Files/Darwin Streaming Server/Logs/streamingadminserver.log",
	  "log", "1",
	  "logclear", "0",
	  "logtime", "168"  
	  );
}
else {
	%vital = ("port", 1220,
	  "root", "/var/streaming/AdminHtml",
	  "server", "DSS 3.0 Admin Server/1.0",
	  "index_docs", "index.html index.htm index.cgi",
	  "addtype_html", "text/html",
          "addtype_htm", "text/html",
	  "addtype_txt", "text/plain",
	  "addtype_gif", "image/gif",
	  "addtype_jpg", "image/jpeg",
	  "addtype_jpeg", "image/jpeg",
	  "addtype_cgi", "internal/cgi",
	  "realm", "DSS Admin Server",
	  "qtssIPAddress", "localhost",
	  "qtssPort", "554",
	  "qtssName", "/usr/local/sbin/DarwinStreamingServer",
	  "logfile", "/var/streaming/logs/streamingadminserver.log",
	  "log", "1",
	  "logclear", "0",
	  "logtime", "168"  
	  );
}
foreach $v (keys %vital) {
	if (!$config{$v}) {
		if ($vital{$v} eq "") {
	    	die "Missing config option $v";
		}
		$config{$v} = $vital{$v};
    }
}

# init days and months for http_date
@weekday = ( "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" );
@month = ( "Jan", "Feb", "Mar", "Apr", "May", "Jun",
	   "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" );

# Change dir to the server root
chdir($config{'root'});
if ($^O ne "MSWin32") {
    $user_homedir = (getpwuid($<))[7];
}

# Read users file
#if ($config{'userfile'}) {
#    open(USERS, $config{'userfile'});
#    while(<USERS>) {
#		if (/^([^:\s]+):([^:\s]+):(\d*):(.*)/) {
#	    	$users{$1} = $2;
#	    	$certs{$1} = $4;
#		}
#		elsif (/^([^:\s]+):([^:\s]+)/) {
#	    	$users{$1} = $2;
#		}
#   }
#   close(USERS);
#}

## Read MIME types file and add extra types
#if ($config{"mimetypes"} ne "") {
#    open(MIME, $config{"mimetypes"});
#    while(<MIME>) {
#	 	chop;
#		/^(\S+)\s+(.*)$/;
#		$type = $1; @exts = split(/\s+/, $2);
#		foreach $ext (@exts) {
#		    $mime{$ext} = $type;
#		}
#    }
#    close(MIME);
#}

foreach $k (keys %config) {
    if ($k !~ /^addtype_(.*)$/) { next; }
    $mime{$1} = $config{$k};
}

# Open main socket
$proto = getprotobyname('tcp');
$baddr = $config{"bind"} ? inet_aton($config{"bind"}) : INADDR_ANY;
$port = $config{"port"};
$servaddr = sockaddr_in($port, $baddr);
socket(MAIN, PF_INET, SOCK_STREAM, $proto) ||
	die "Failed to open listening socket for Streaming Admin Server : $!\n";
setsockopt(MAIN, SOL_SOCKET, SO_REUSEADDR, pack("l", 1));
bind(MAIN, $servaddr) || die "Failed to start Streaming Admin Server.\n"
								. "Port $config{port} is in use by another process.\n"
								. "The Streaming Admin Server may already be running.\n";  

listen(MAIN, SOMAXCONN) || die "Failed to listen on socket for Streaming Admin Server: $!\n";

# Split from the controlling terminal
if ($^O ne "MSWin32") {
 	if (fork()) {
		exit;
 	}
	setsid();
}

# write out the PID file
# Not used for NT
#if ($^O ne "MSWin32") {
#    open(PIDFILE, "> $config{'pidfile'}");
#    printf PIDFILE "%d\n", getpid();
#    close(PIDFILE);
#}

# check if the streaming server is running by trying to connect
# to it. If the server doesn't respond, look for the name of the 
# streaming server binary in the config file and start it
if(!($iaddr = inet_aton($config{'qtssIPAddress'}))) { 
		print "No host: $config{'qtssIPAddress'}\n";			
}
$paddr = sockaddr_in($config{'qtssPort'}, $iaddr);
$proto = getprotobyname('tcp');
if(!socket(TEST_SOCK, PF_INET, SOCK_STREAM, $proto)) {
	print "Coudn't create socket to connect to the Streaming Server: $!\n";
}
if(!connect(TEST_SOCK, $paddr)) {
    print "Couldn't connect to the Streaming Server at $config{'qtssIPAddress'} "
	. " on port $config{'qtssPort'}\n";
    if($^O eq "MSWin32") {
	print "Please start Darwin Streaming Server from the Service Manager\n";
    }
    else {
	print "Trying to launch...\n";
    }
    $prog = $config{'qtssName'};
    if($^O ne "MSWin32") {
	if(!($forkpid = fork())) {
	    close(MAIN);
	    if(exec($prog)) {
		print "Launched the streaming server.\n";
	    }  
	    else {
		print "Cannot launch $prog: $?\n"; 
	    }
	    exit;
	}
	#if(system($prog) != 0) {
	#   print "Cannot launch $prog: $?";
	#}
	#else {
	#   print "Launched the streaming server.\n";
	#}
    }
    else {
	#eval "require Win32::Service";
	#if($@) {
	#	print "Win32::Service module not installed.\n"
	#		. "Cannot launch the Streaming Server from the admin server\n";
	#}
	#else {
	#	Win32::Service::StartService(NULL, "Darwin Streaming Server");
	#}
	
	#eval "require Win32::Process";
	#if($@) {
	#	print "Win32::Process module not installed.\n"
	#		. "Cannot launch the Streaming Server from the admin server\n";
	#}
	#else {
	#	if(Win32::Process::Create($processObj, $prog, "", 0, DETACHED_PROCESS, ".") == 0) { 
	#		print "Failed to launch the Streaming Server\n";
	#	}
	#	else {
	#		$processObj->SetPriorityClass(NORMAL_PRIORITY_CLASS) 
	#			|| print "Couldn't set the priority of the Streaming Server process\n";
	#		$processObj->Wait(0);
	#		print "Launched the Streaming Server\n";
	#	}
	#}
    }
}
close(TEST_SOCK);


# Start the log-clearing process, if needed. This checks every minute
# to see if the log has passed its reset time, and if so clears it
if ($^O ne "MSWin32") {
    if ($config{'logclear'}) {
		if (!($logclearer = fork())) {
	    	while(1) {
				$write_logtime = 0;
				if (open(LOGTIME, "$config{'logfile'}.time")) {
		    		<LOGTIME> =~ /(\d+)/;
		    		close(LOGTIME);
		    		if ($1 && $1+$config{'logtime'}*60*60 < time()){
						# need to clear log
						$write_logtime = 1;
						unlink($config{'logfile'});
		    		}
				}
				else { $write_logtime = 1; }
				if ($write_logtime) {
		    		open(LOGTIME, ">$config{'logfile'}.time");
		    		print LOGTIME time(),"\n";
		    		close(LOGTIME);
				}
				sleep(5*60);
	    	}
	    	exit;
		}
		push(@childpids, $logclearer);
    }
}

# get the time zone
if ($config{'log'}) {
    local(@gmt, @lct, $days, $hours, $mins);
    @make_date_marr = ("Jan", "Feb", "Mar", "Apr", "May", "Jun",
		       "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
    @gmt = gmtime(time());
    @lct = localtime(time());
    $days = $lct[3] - $gmt[3];
    $hours = ($days < -1 ? 24 : 1 < $days ? -24 : $days * 24) +
	$lct[2] - $gmt[2];
    $mins = $hours * 60 + $lct[1] - $gmt[1];
    $timezone = ($mins < 0 ? "-" : "+"); $mins = abs($mins);
    $timezone .= sprintf "%2.2d%2.2d", $mins/60, $mins%60;
}

# Run the main loop
if ($^O ne "MSWin32") {
	$SIG{'CHLD'} = 'streamingadminserver::reaper';
    $SIG{'TERM'} = 'streamingadminserver::term_handler';
    $SIG{'HUP'} = 'streamingadminserver::trigger_restart';
}
$SIG{'PIPE'} = 'IGNORE';
@deny = &to_ipaddress(split(/\s+/, $config{"deny"}));
@allow = &to_ipaddress(split(/\s+/, $config{"allow"}));
$p = 0;
while(1) {
    # wait for a new connection, or a message from a child process
    undef($rmask);
    vec($rmask, fileno(MAIN), 1) = 1;
    if($^O ne "MSWin32") {
		if ($config{'passdelay'}) {
	    	for($i=0; $i<@passin; $i++) {
				vec($rmask, fileno($passin[$i]), 1) = 1;
	    	}
		}
    }

    local $sel = select($rmask, undef, undef, undef);
    if ($need_restart) { &restart_streamingadminserver(); }
    
    #if($^O ne "MSWin32") {
	#	# Clean up finished processes
	#	local($pid);
	#	do {
	#    	$pid = waitpid(-1, WNOHANG);
	#    	print "reaped child $pid\n";
	#    	@childpids = grep { $_ != $pid } @childpids;
	#		print "remaining children @childpids\n";
	#	} while($pid > 0);
    #}

    next if ($sel <= 0);
    
    if (vec($rmask, fileno(MAIN), 1)) {
		# got new connection
		$acptaddr = accept(SOCK, MAIN);
		
		if (!$acptaddr) { next; }
	
	
		if($^O ne "MSWin32") {
	    	# create pipes
	    	if ($config{'passdelay'}) {
				$PASSINr = "PASSINr$p"; $PASSINw = "PASSINw$p";
				$PASSOUTr = "PASSOUTr$p"; $PASSOUTw = "PASSOUTw$p";
				$p++;
				pipe($PASSINr, $PASSINw);
				pipe($PASSOUTr, $PASSOUTw);
				select($PASSINw); $| = 1;
				select($PASSOUTw); $| = 1;
		 	}
		}
	
		select(SOCK); $| = 1;
		select(STDOUT);

		if($^O eq "MSWin32") {
		    # Work out the hostname for this web server
		    if (!$config{'host'}) {
				($myport, $myaddr) =
			    	unpack_sockaddr_in(getsockname(SOCK));
				$myname = gethostbyaddr($myaddr, AF_INET);
				if ($myname eq "") {
				    $myname = inet_ntoa($myaddr);
				}
				$host = $myname;
		    }
		    else { $host = $config{'host'}; }
		    $port = $config{'port'};
	    
		    while(&handle_request($acptaddr)) { }
	    	close(SOCK);
		}
		else {
		    # fork the subprocess
		    if (!($handpid = fork())) {
				# setup signal handlers
				$SIG{'TERM'} = 'DEFAULT';
				$SIG{'PIPE'} = 'DEFAULT';
				#$SIG{'CHLD'} = 'IGNORE';
				$SIG{'HUP'} = 'IGNORE';
				# close useless pipes
				if ($config{'passdelay'}) {
				    foreach $p (@passin) { close($p); }
				    foreach $p (@passout) { close($p); }
				    close($PASSINr); close($PASSOUTw);
				}
				close(MAIN);
		
				# Work out the hostname for this web server
				if (!$config{'host'}) {
				    ($myport, $myaddr) =
						unpack_sockaddr_in(getsockname(SOCK));
				    $myname = gethostbyaddr($myaddr, AF_INET);
				    if ($myname eq "") {
						$myname = inet_ntoa($myaddr);
				    }
		    		$host = $myname;
				}
				else { $host = $config{'host'}; }
				$port = $config{'port'};
		
				while(&handle_request($acptaddr)) { }
				close(SOCK);
				close($PASSINw); close($PASSOUTw);
				exit;
	    	}
		    # push(@childpids, $handpid);
		    if ($config{'passdelay'}) {
				close($PASSINw); close($PASSOUTr);
				push(@passin, $PASSINr); push(@passout, $PASSOUTw);
	    	}
	    	close(SOCK);
		}
    }

    if($^O ne "MSWin32") {
		# check for password-timeout messages from subprocesses
		for($i=0; $i<@passin; $i++) {
		    if (vec($rmask, fileno($passin[$i]), 1)) {
				# this sub-process is asking about a password
				$infd = $passin[$i]; $outfd = $passout[$i];
				if (<$infd> =~ /^(\S+)\s+(\S+)\s+(\d+)/) {
				    # Got a delay request from a subprocess.. for
		    		# valid logins, there is no delay (to prevent
		    		# denial of service attacks), but for invalid
		    		# logins the delay increases with each failed
		    		# attempt.
		    		#print STDERR "got $1 $2 $3\n";
		    		if ($3) {
						# login OK.. no delay
						print $outfd "0\n";
				    }
				    else {
						# login failed.. 
						$dl = $userdlay{$1} -
					    int((time() - $userlast{$1})/50);
						$dl = $dl < 0 ? 0 : $dl+1;
						print $outfd "$dl\n";
						$userdlay{$1} = $dl;
		    		}
		   			$userlast{$1} = time();
				}
				else {
				    # close pipe
				    close($infd); close($outfd);
				    $passin[$i] = $passout[$i] = undef;
				}
	    	}
		}
		@passin = grep { defined($_) } @passin;
		@passout = grep { defined($_) } @passout;
	}
}

# handle_request(address)
# Where the real work is done
sub handle_request
{
    $acptip = inet_ntoa((unpack_sockaddr_in($_[0]))[1]);
    $datestr = &http_date(time());
    
    # Read the HTTP request and headers
    ($reqline = &read_line()) =~ s/\r|\n//g;
    if (!($reqline =~ /^(GET|POST|HEAD)\s+(.*)\s+HTTP\/1\..$/)) {
	&http_error(400, "Bad Request");
    }
    $method = $1; $request_uri = $page = $2;
    %header = ();
    while(1) {
		($headline = &read_line()) =~ s/\r|\n//g;
		if ($headline eq "") { last; }
		($headline =~ /^(\S+):\s+(.*)$/) || &http_error(400, "Bad Header");
		$header{lc($1)} = $2;
    }
    if (defined($header{'host'})) {
		if ($header{'host'} =~ /^([^:]+):([0-9]+)$/) { 
	    	$host = $1; 
	    	$port = $2; 
		}
		else { $host = $header{'host'}; }
    }
    if ($page =~ /^([^\?]+)\?(.*)$/) {
		# There is some query string information
		$page = $1;
		$querystring = $2;
		if ($querystring !~ /=/) {
	    	$queryargs = $querystring;
	    	$queryargs =~ s/\+/ /g;
	    	$queryargs =~ s/%(..)/pack("c",hex($1))/ge;
	    	$querystring = "";
		}
    }

    # strip NULL characters %00 from the request
    $page =~ s/%00//ge;

    # replace %XX sequences in page
    $page =~ s/%(..)/pack("c",hex($1))/ge;
  
    # check address against access list
    if (@deny && &ip_match($acptip, @deny) ||
		@allow && !&ip_match($acptip, @allow)) {
		&http_error(403, "Access denied for $acptip");
		return 0;
    }

    # check for the logout flag file, and if existant deny authentication once
    if ($config{'logout'} && -r $config{'logout'}) {
		&write_data("HTTP/1.0 401 Unauthorized\r\n");
		&write_data("Server: $config{server}\r\n");
		&write_data("Date: $datestr\r\n");
		&write_data("WWW-authenticate: Basic ".
			    "realm=\"$config{realm}\"\r\n");
		&write_data("Content-Type: text/html\r\n");
		&write_keep_alive(0);
		&write_data("\r\n");
		&reset_byte_count();
		&write_data("<html>\n<head>\n<title>Please Login</title>\n</head>\n");
		&write_data("<body>\n<h1>Please Login</h1>\n");
		&write_data("<p>Please login to the server as a new user.</p>\n</body>\n</html>\n");
		&log_request($acptip, undef, $reqline, 401, &byte_count());
		unlink($config{'logout'});
		return 0;
    }

    # Check for password if needed
    if (%users) {
		$validated = 0;
	
		# Check for normal HTTP authentication
		if (!$validated && $header{authorization} =~ /^basic\s+(\S+)$/i) {
	    	# authorization given..
	    	($authuser, $authpass) = split(/:/, &b64decode($1));
	    	if($^O eq "MSWin32") {
				if ($authuser && ($users{$authuser} eq $authpass)) {
		    		$validated = 1;
				}
	    	}
	    	else {
				if ($authuser && $users{$authuser} && $users{$authuser} eq
		    				crypt($authpass, $users{$authuser})) {
		    		$validated = 1;
				}
	    	}
	    	#print STDERR "checking $authuser $authpass -> $validated\n";

	    	if($^O ne "MSWin32") {
				if ($config{'passdelay'}) {
		    		# check with main process for delay
		    		print $PASSINw "$authuser $acptip $validated\n";
		    		<$PASSOUTr> =~ /(\d+)/;
		    		#print STDERR "sleeping for $1\n";
		    		sleep($1);
				}
	    	}
		}
		if (!$validated) {
		    # No password given.. ask
		    &write_data("HTTP/1.0 401 Unauthorized\r\n");
		    &write_data("Server: $config{'server'}\r\n");
		    &write_data("Date: $datestr\r\n");
		    &write_data("WWW-authenticate: Basic ".
				"realm=\"$config{'realm'}\"\r\n");
		    &write_data("Content-Type: text/html\r\n");
		    &write_keep_alive(0);
		    &write_data("\r\n");
		    &reset_byte_count();
		    &write_data("<html>\n<head>\n<title>Unauthorized</title>\n</head>\n");
		    &write_data("<body>\n<h1>Unauthorized</h1>\n");
		    &write_data("<p>A password is required to access this\n");
		    &write_data("web server. Please try again. </p>\n</body>\n</html>\n");
		    &log_request($acptip, undef, $reqline, 401, &byte_count());
	   		return 0;
		}

		# Check per-user IP access control
		if ($deny{$authuser} && &ip_match($acptip, @{$deny{$authuser}}) ||
			    $allow{$authuser} && !&ip_match($acptip, @{$allow{$authuser}})) {
			&http_error(403, "Access denied for $acptip");
			return 0;
		}	
	
    }
    
    # Figure out what kind of page was requested
    $simple = &simplify_path($page, $bogus);
    if ($bogus) {
		&http_error(400, "Invalid path");
    }
    $sofar = ""; $full = $config{"root"} . $sofar;
    $scriptname = $simple;
    foreach $b (split(/\//, $simple)) {
		if ($b ne "") { $sofar .= "/$b"; }
		$full = $config{"root"} . $sofar;
		@st = stat($full);
		if (!@st) { &http_error(404, "File not found"); }
	
		# Check if this is a directory
		if (-d $full) {
	    	# It is.. go on parsing
	    	next;
		}
	
		# Check if this is a CGI program
		if (&get_type($full) eq "internal/cgi") {
		    $pathinfo = substr($simple, length($sofar));
		    $pathinfo .= "/" if ($page =~ /\/$/);
	    	$scriptname = $sofar;
	    	last;
		}
    }

    # check filename against denyfile regexp
    local $denyfile = $config{'denyfile'};
    if ($denyfile && $full =~ /$denyfile/) {
		&http_error(403, "Access denied to $page");
		return 0;
    }

    # Reached the end of the path OK.. see what we've got
    if (-d $full) {
    	# See if the URL ends with a / as it should
		if ($page !~ /\/$/) {
	    	# It doesn't.. redirect
	   		&write_data("HTTP/1.0 302 Moved Temporarily\r\n");
	    	$portstr = ($port == 80) ? "" : ":$port";
	    	&write_data("Date: $datestr\r\n");
	    	&write_data("Server: $config{'server'}\r\n");
	    	$prot = "http";
	    	&write_data("Location: $prot://$host$portstr$page/\r\n");
	    	&write_keep_alive(0);
	    	&write_data("\r\n");
	    	&log_request($acptip, $authuser, $reqline, 302, 0);
	    	return 0;
		}
		# A directory.. check for index files
		foreach $idx (split(/\s+/, $config{'index_docs'})) {
	    	$idxfull = "$full/$idx";
	    	if (-r $idxfull && !(-d $idxfull)) {
				$full = $idxfull;
				$scriptname .= "/" if ($scriptname ne "/");
				last;
		    }
		}
    }

    if (-d $full) {
		# For now, a directory shouldn't be listed.
		# Instead a 404 should be returned
		&http_error(404, "File not found");
		
		# This is definitely a directory.. list it
		#&write_data("HTTP/1.0 200 OK\r\n");
		#&write_data("Date: $datestr\r\n");
		#&write_data("Server: $config{'server'}\r\n");
		#&write_data("Content-Type: text/html\r\n");
		#&write_keep_alive(0);
		#&write_data("\r\n");
		#&reset_byte_count();
		#&write_data("<html>\n<body>\n<h1>Index of $simple</h1>\n");
		#&write_data("<pre>\n");
		#&write_data(sprintf "%-35.35s %-20.20s %-10.10s\n", "Name", "Last Modified", "Size");
		#&write_data("<hr>\n");
		#opendir(DIR, $full);
		#while($df = readdir(DIR)) {
		#    if ($df =~ /^\./) { next; }
		#    (@stbuf = stat("$full/$df")) || next;
		#    if (-d "$full/$df") { $df .= "/"; }
	    #	@tm = localtime($stbuf[9]);
	    #	$fdate = sprintf "%2.2d/%2.2d/%4.4d %2.2d:%2.2d:%2.2d",
	    #	$tm[3],$tm[4]+1,$tm[5]+1900,
	    #	$tm[0],$tm[1],$tm[2];
	    #	$len = length($df); $rest = " "x(35-$len);
	    #	&write_data(sprintf 
		#		"<a href=\"%s\">%-${len}.${len}s</a>$rest %-20.20s %-10.10s\n",
		#		$df, $df, $fdate, $stbuf[7]);
		#}
		#closedir(DIR);
		#&write_data("</body>\n</html>\n");	
		#&log_request($acptip, $authuser, $reqline, 200, &byte_count());
		return 0;
    }

    # CGI or normal file
    local $rv;
    if (&get_type($full) eq "internal/cgi") {
		# A CGI program to execute
		$envtz = $ENV{"TZ"};
		$envuser = $ENV{"USER"};
		$envpath = $ENV{"PATH"};
		foreach (keys %ENV) { delete($ENV{$_}); }
		$ENV{'PATH'} = $envpath if ($envpath);
		$ENV{"TZ"} = $envtz if ($envtz);
		$ENV{"USER"} = $envuser if ($envuser);
		$ENV{"HOME"} = $user_homedir;
		$ENV{"SERVER_SOFTWARE"} = $config{"server"};
		$ENV{"SERVER_NAME"} = $host;
		$ENV{"SERVER_ADMIN"} = $config{"email"};
		$ENV{"SERVER_ROOT"} = $config{"root"};
		$ENV{"SERVER_PORT"} = $port;
		$ENV{"REMOTE_HOST"} = $acptip;
		$ENV{"REMOTE_ADDR"} = $acptip;
		$ENV{"REMOTE_USER"} = $authuser if (defined($authuser));
		$ENV{"DOCUMENT_ROOT"} = $config{"root"};
		$ENV{"GATEWAY_INTERFACE"} = "CGI/1.1";
		$ENV{"SERVER_PROTOCOL"} = "HTTP/1.0";
		$ENV{"REQUEST_METHOD"} = $method;
		$ENV{"SCRIPT_NAME"} = $scriptname;
		$ENV{"REQUEST_URI"} = $request_uri;
		$ENV{"PATH_INFO"} = $pathinfo;
		$ENV{"PATH_TRANSLATED"} = "$config{root}/$pathinfo";
		$ENV{"QUERY_STRING"} = $querystring;
		$ENV{"QTSSADMINSERVER_CONFIG"} = $conf;
		$ENV{"QTSSADMINSERVER_QTSSIP"} = $config{"qtssIPAddress"};
		$ENV{"QTSSADMINSERVER_QTSSPORT"} = $config{"qtssPort"};
		$ENV{"QTSSADMINSERVER_QTSSNAME"} = $config{"qtssName"};
		$ENV{"HTTPS"} = "OFF";
		if (defined($header{"content-length"})) {
	    	$ENV{"CONTENT_LENGTH"} = $header{"content-length"};
		}
		if (defined($header{"content-type"})) {
	    	$ENV{"CONTENT_TYPE"} = $header{"content-type"};
		}
		foreach $h (keys %header) {
		    ($hname = $h) =~ tr/a-z/A-Z/;
		    $hname =~ s/\-/_/g;
		    $ENV{"HTTP_$hname"} = $header{$h};
		}
		$full =~ /^(.*\/)[^\/]+$/; $ENV{"PWD"} = $1;
		foreach $k (keys %config) {
		    if ($k =~ /^env_(\S+)$/) {
				$ENV{$1} = $config{$k};
	    	}
		}
	
		# Check if the CGI can be handled internally
		open(CGI, $full);
		local $first = <CGI>;
		close(CGI);
		$perl_cgi = 0;
		if ($^O eq "MSWin32") {
		    if ($first =~ m/^#!(.*)perl$/i) {
				$perl_cgi = 1;
	    	}
		}
		else {
	    	if ($first =~ m/#!$perl_path(\r|\n)/ && $] >= 5.004) {
				$perl_cgi = 1;
	    	}
		}
		if($perl_cgi == 1) {
	    	# setup environment for eval
	    	chdir($ENV{"PWD"});
	    	@ARGV = split(/\s+/, $queryargs);
	    	$0 = $full;
	    	if ($method eq "POST") {
				$clen = $header{"content-length"};
				while(length($postinput) < $clen) {
		    		$buf = &read_data($clen - length($postinput));
		    		if (!length($buf)) {
						&http_error(500, "Failed to read ".
				    	"POST request");
		    		}
		    		$postinput .= $buf;
				}
	    	}
	    
	    	if($^O ne "MSWin32") {
				$SIG{'CHLD'} = 'DEFAULT';
		    	eval {
		    		# Have SOCK closed if the perl exec's something
					use Fcntl;
					fcntl(SOCK, F_SETFD, FD_CLOEXEC);
				};
			}
	    
	    	if ($config{'log'}) {
				open(QTSSADMINSERVERLOG, ">>$config{'logfile'}");
				chmod(0600, $config{'logfile'});
	    	}
	    	# set doneheaders = 1 so that the cgi spits out all the headers
	    	$doneheaders = 1;
	    	
	    	$doing_eval = 1;
	    	eval {
				package main;
				tie(*STDOUT, 'streamingadminserver');
				tie(*STDIN, 'streamingadminserver');
				do $streamingadminserver::full;
				die $@ if ($@);
	    	};
	    	$doing_eval = 0;
	    	if ($@) {
				# Error in perl!
				&http_error(500, "Perl execution failed", $@);
	    	}
	    	elsif (!$doneheaders) {
				&http_error(500, "Missing Header");
	    	}
	    
		    if($^O ne "MSWin32") {
				close(SOCK);
	    	}
	    	if($^O eq "MSWin32") {
				untie(*STDOUT);
				untie(*STDIN);
				$doneheaders = 0;
	    	}
	    	$rv = 0;
		} 
		else {
	    	if($^O ne "MSWin32") {
				# fork the process that actually executes the CGI
				pipe(CGIINr, CGIINw);
				pipe(CGIOUTr, CGIOUTw);
				pipe(CGIERRr, CGIERRw);
				if (!($cgipid = fork())) {
		    		chdir($ENV{"PWD"});
		    		close(SOCK);
		    		open(STDIN, "<&CGIINr");
		    		open(STDOUT, ">&CGIOUTw");
		    		open(STDERR, ">&CGIERRw");
		    		close(CGIINw); close(CGIOUTr); close(CGIERRr);
		    		exec($full, split(/\s+/, $queryargs));
		    		print STDERR "Failed to exec $full : $!\n";
		    		exit;
				}
				close(CGIINr); close(CGIOUTw); close(CGIERRw);
		
				# send post data
				if ($method eq "POST") {
		   	 		$got = 0; $clen = $header{"content-length"};
		    		while($got < $clen) {
						$buf = &read_data($clen-$got);
						if (!length($buf)) {
						    kill('TERM', $cgipid);
						    &http_error(500, "Failed to read ".
							"POST request");
						}
						$got += length($buf);
						print CGIINw $buf;
		    		}
				}
				close(CGIINw);
		
				# read back cgi headers
				select(CGIOUTr); $|=1; select(STDOUT);
				$got_blank = 0;
				$cgi_statusline = "";
				while(1) {
				    $line = <CGIOUTr>;
				    # check if the first line of the cgi is the status line
				    my $http_version = "HTTP/1.0";
					if(($cgi_statusline eq "") && !%cgiheader && ($line =~ m/$http_version\s(.*)(\r|\n)/)) {
						 $cgi_statusline = $line;
		 				 next;
		   			}
		    		$line =~ s/\r|\n//g;
		    		if ($line eq "") {
						if ($got_blank || %cgiheader) { last; }
						$got_blank++;
						next;
		    		}
		    		($line =~ /^(\S+):\s+(.*)$/) ||
						&http_error(500, "Bad Header",
				    	&read_errors(CGIERRr));
		    		$cgiheader{lc($1)} = $2;
		    	}
				if($cgi_statusline ne "") {
					&write_data($cgi_statusline);
				}
				else {
					if ($cgiheader{"location"}) {
		    			&write_data("HTTP/1.0 302 Moved Temporarily\r\n");
		    			# ignore the rest of the output. This is a hack, but
				    	# is necessary for IE in some cases :(
		    			close(CGIOUTr); close(CGIERRr);
					}	
					elsif ($cgiheader{"content-type"} eq "") {
		    			&http_error(500, "Missing Content-Type Header",
						&read_errors(CGIERRr));
					}
					else {
		    			&write_data("HTTP/1.0 200 OK\r\n");
		    			&write_data("Date: $datestr\r\n");
		    			&write_data("Server: $config{server}\r\n");
		    			&write_keep_alive(0);
					}
				}
				foreach $h (keys %cgiheader) {
		    		&write_data("$h: $cgiheader{$h}\r\n");
				}
				&write_data("\r\n");
				&reset_byte_count();
				while($line = <CGIOUTr>) { &write_data($line); }
				close(CGIOUTr); close(CGIERRr);
				$rv = 0;
	    	}
		}
    }
    else {
		# A file to output
		local @st = stat($full);
		open(FILE, $full) || &http_error(404, "Failed to open file");
	
		# The read call in Windows interprets the end of lines
		# unless it is opened in binary mode
		if ($^O eq "MSWin32") {
		    binmode( FILE );
		}
	
		&write_data("HTTP/1.0 200 OK\r\n");
		&write_data("Date: $datestr\r\n");
		&write_data("Server: $config{server}\r\n");
		&write_data("Content-Type: ".&get_type($full)."\r\n");
		&write_data("Content-Length: $st[7]\r\n");
		&write_data("Last-Modified: ".&http_date($st[9])."\r\n");
		if ($^O eq "MSWin32") {
		    # Since it is one process handling all connections, we can't keep a connection alive
		    &write_keep_alive(0);
		}
		else {
	    	&write_keep_alive();
		}	
		&write_data("\r\n");
		&reset_byte_count();
		while(read(FILE, $buf, 1024) > 0) {
		    &write_data($buf);
		}
		close(FILE);
		if($^O eq "MSWin32") {
	    	# can't do keep alive when we're just a single process
	   		$rv = 0;
		}
		else {
	    	$rv = &check_keep_alive();
		}
	}
    # log the request
    &log_request($acptip, $authuser, $reqline,
		 $cgiheader{"location"} ? "302" : "200", &byte_count());
    return $rv;
}

# http_error(code, message, body, [dontexit])
sub http_error
{
    close(CGIOUT);
    &write_data("HTTP/1.0 $_[0] $_[1]\r\n");
    &write_data("Server: $config{server}\r\n");
    &write_data("Date: $datestr\r\n");
    &write_data("Content-Type: text/html\r\n");
    &write_keep_alive(0);
    &write_data("\r\n");
    &reset_byte_count();
    &write_data("<html><body>\n");
    &write_data("<h1>Error - $_[1]</h1>\n");
    if ($_[2]) {
	&write_data("<pre>$_[2]</pre>\n");
    }
    &write_data("</body></html>\n");
    &log_request($acptip, $authuser, $reqline, $_[0], &byte_count());
    if ($^O ne "MSWin32") {
	exit if (!$_[3]);
    }
}

sub get_type
{
    if ($_[0] =~ /\.([A-z0-9]+)$/) {
	$t = $mime{$1};
	if ($t ne "") {
	    return $t;
	}
    }
    return "text/plain";
}

# simplify_path(path, bogus)
# Given a path, maybe containing stuff like ".." and "." convert it to a
# clean, absolute form.
sub simplify_path
{
    local($dir, @bits, @fixedbits, $b);
    $dir = $_[0];
    $dir =~ s/^\/+//g;
    $dir =~ s/\/+$//g;
    @bits = split(/\/+/, $dir);
    @fixedbits = ();
    $_[1] = 0;
    foreach $b (@bits) {
        if ($b eq ".") {
	    # Do nothing..
        }
        elsif ($b eq "..") {
	    # Remove last dir
	    if (scalar(@fixedbits) == 0) {
		$_[1] = 1;
		return "/";
	    }
	    pop(@fixedbits);
	}
        else {
	    # Add dir to list
	    push(@fixedbits, $b);
	}
    }
    return "/" . join('/', @fixedbits);
}

# b64decode(string)
# Converts a string from base64 format to normal
sub b64decode
{
    local($str) = $_[0];
    local($res);
    $str =~ tr|A-Za-z0-9+=/||cd;
    $str =~ s/=+$//;
    $str =~ tr|A-Za-z0-9+/| -_|;
    while ($str =~ /(.{1,60})/gs) {
        my $len = chr(32 + length($1)*3/4);
        $res .= unpack("u", $len . $1 );
    }
    return $res;
}

# ip_match(ip, [match]+)
# Checks an IP address against a list of IPs, networks and networks/masks
sub ip_match
{
    local(@io, @mo, @ms, $i, $j);
    @io = split(/\./, $_[0]);
    for($i=1; $i<@_; $i++) {
	local $mismatch = 0;
	if ($_[$i] =~ /^(\S+)\/(\S+)$/) {
	    # Compare with network/mask
	    @mo = split(/\./, $1); @ms = split(/\./, $2);
	    for($j=0; $j<4; $j++) {
		if ((int($io[$j]) & int($ms[$j])) != int($mo[$j])) {
		    $mismatch = 1;
		}
	    }
	}
	else {
	    # Compare with IP or network
	    @mo = split(/\./, $_[$i]);
	    while(@mo && !$mo[$#mo]) { pop(@mo); }
	    for($j=0; $j<@mo; $j++) {
		if ($mo[$j] != $io[$j]) {
		    $mismatch = 1;
		}
	    }
	}
	return 1 if (!$mismatch);
    }
    return 0;
}

# restart_streamingadminserver()
# Called when a SIGHUP is received to restart the web server. This is done
# by exec()ing perl with the same command line as was originally used
sub restart_streamingadminserver
{
    close(SOCK); close(MAIN);
    foreach $p (@passin) { close($p); }
    foreach $p (@passout) { close($p); }
    if ($logclearer) { kill('TERM', $logclearer);	}
    exec($perl_path, $streamingadminserver_path, @streamingadminserver_argv);
    die "Failed to restart streamingadminserver with $perl_path $streamingadminserver_path";
}

sub trigger_restart
{
    $need_restart = 1;
}

sub to_ipaddress
{
    local (@rv, $i);
    foreach $i (@_) {
	if ($i =~ /(\S+)\/(\S+)/) { push(@rv, $i); }
	else { push(@rv, join('.', unpack("CCCC", inet_aton($i)))); }
    }
    return @rv;
}

# read_line()
# Reads one line from SOCK
sub read_line
{
    return <SOCK>; 
}


# read_data(length)
# Reads up to some amount of data from SOCK
sub read_data
{
    local($buf);
    read(SOCK, $buf, $_[0]) || return undef;
    return $buf;
}


# write_data(data)
# Writes a string to SOCK
sub write_data
{
    print SOCK $_[0];
    $write_data_count += length($_[0]);
}

# reset_byte_count()
sub reset_byte_count { $write_data_count = 0; }

# byte_count()
sub byte_count { return $write_data_count; }

# log_request(address, user, request, code, bytes)
sub log_request
{
    if ($config{'log'}) {
    	local(@tm, $dstr, $addr, $user, $ident);
	if ($config{'logident'}) {
	    # add support for rfc1413 identity checking here
	}
	else { $ident = "-"; }
	@tm = localtime(time());
	$dstr = sprintf "%2.2d/%s/%4.4d:%2.2d:%2.2d:%2.2d %s",
	$tm[3], $make_date_marr[$tm[4]], $tm[5]+1900,
	$tm[2], $tm[1], $tm[0], $timezone;
	$addr = $config{'loghost'} ? gethostbyaddr(inet_aton($_[0]), AF_INET)
	    : $_[0];
	$user = $_[1] ? $_[1] : "-";
	if (fileno(QTSSADMINSERVERLOG)) {
	    seek(QTSSADMINSERVERLOG, 0, 2);
	}
	else {
	    open(QTSSADMINSERVERLOG, ">>$config{'logfile'}");
	    chmod(0600, $config{'logfile'});
	}
	print QTSSADMINSERVERLOG "$addr $ident $user [$dstr] \"$_[2]\" $_[3] $_[4]\n";
	close(QTSSADMINSERVERLOG);
    }
}

# read_errors(handle)
# Read and return all input from some filehandle
sub read_errors
{
    local($fh, $_, $rv);
    $fh = $_[0];
    while(<$fh>) { $rv .= $_; }
    return $rv;
}

sub write_keep_alive
{
    local $mode;
    if (@_) { $mode = $_[0]; }
    else { $mode = &check_keep_alive(); }
    &write_data("Connection: ".($mode ? "Keep-Alive" : "close")."\r\n");
}

sub check_keep_alive
{
    return $header{'connection'} =~ /keep-alive/i;
}


sub reaper
{
	local($pid);
	do {
	    $pid = waitpid(-1, WNOHANG);
	} while($pid > 0);
}

sub term_handler
{
    if (@childpids) {
		kill('TERM', @childpids);
    }
    exit(1);
}

sub http_date
{
    local @tm = gmtime($_[0]);
    return sprintf "%s, %d %s %d %2.2d:%2.2d:%2.2d GMT",
    $weekday[$tm[6]], $tm[3], $month[$tm[4]], $tm[5]+1900,
    $tm[2], $tm[1], $tm[0];
}

sub TIEHANDLE
{
    my $i; bless \$i, shift;
}

sub WRITE
{
    $r = shift;
    my($buf,$len,$offset) = @_;
    &write_to_sock(substr($buf, $offset, $len));
}

sub PRINT
{
    $r = shift;
    $$r++;
    &write_to_sock(@_);
}

sub PRINTF
{
    shift;
    my $fmt = shift;
    &write_to_sock(sprintf $fmt, @_);
}

sub READ
{
    $r = shift;
    substr($_[0], $_[2], $_[1]) = substr($postinput, $postpos, $_[1]);
    $postpos += $_[1];
}

sub OPEN
{
print STDERR "open() called - should never happen!\n";
}
 
sub READLINE
{
    if ($postpos >= length($postinput)) {
	return undef;
    }
    local $idx = index($postinput, "\n", $postpos);
    if ($idx < 0) {
	local $rv = substr($postinput, $postpos);
	$postpos = length($postinput);
	return $rv;
    }
    else {
	local $rv = substr($postinput, $postpos, $idx-$postpos+1);
	$postpos = $idx+1;
	return $rv;
    }
}
 
sub GETC
{
    return $postpos >= length($postinput) ? undef
	: substr($postinput, $postpos++, 1);
}
 
sub CLOSE { }
 
sub DESTROY { }

# write_to_sock(data, ...)
sub write_to_sock
{
    foreach $d (@_) {
	if ($doneheaders) {
	    &write_data($d);
	}
	else {
	    $headers .= $d;
	    while(!$doneheaders && $headers =~ s/^(.*)(\r)?\n//) {
		if ($1 =~ /^(\S+):\s+(.*)$/) {
		    $cgiheader{lc($1)} = $2;
		}
		elsif ($1 !~ /\S/) {
		    $doneheaders++;
		}
		else {
		    &http_error(500, "Bad Header");
		}
	    }
	    if ($doneheaders) {
		if ($cgiheader{"location"}) {
		    &write_data(
				"HTTP/1.0 302 Moved Temporarily\r\n");
		}
		elsif ($cgiheader{"content-type"} eq "") {
		    &http_error(500, "Missing Content-Type Header");
		}
		else {
		    &write_data("HTTP/1.0 200 OK\r\n");
		    &write_data("Date: $datestr\r\n");
		    &write_data("Server: $config{server}\r\n");
		    &write_keep_alive(0);
		}
		foreach $h (keys %cgiheader) {
		    &write_data("$h: $cgiheader{$h}\r\n");
		}
		&write_data("\r\n");
		&reset_byte_count();
		&write_data($headers);
	    }
	}
    }
}

sub END
{
    if ($doing_eval) {
	# A CGI program called exit! This is a horrible hack to 
	# finish up before really exiting
	close(SOCK);
	&log_request($acptip, $authuser, $reqline,
		     $cgiheader{"location"} ? "302" : "200", &byte_count());
    }
}
