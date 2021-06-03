#!/usr/bin/perl

use Socket;
use IO::Socket;
use Time::localtime;
use LWP::Simple qw($ua get);
no warnings qw(redefine prototype);
my $diri = "/home/oracle/scripts/webserver/fila";
my $dirc = "/home/oracle/scripts/webserver/fila";
sub parse_form {
    my $cata = $_[0];
    my %data;
    foreach (split /&/, $cata) {
        my ($key, $val) = split /=/;
        $val =~ s/\+/ /g;
        $val =~ s/%(..)/chr(hex($1))/eg;
        $cata{$key} = $val;}
    return %data; }

# Port WebService

my $port = '5030';
defined($port) or die "Usage: $0 portno\n";
my $server = new IO::Socket::INET(Proto => 'tcp',
                                  LocalPort => $port,
                                  Listen => SOMAXCONN,
                                  Reuse => 1);
$server or die "Unable to create server socket: $!" ;
# Avoid dying from browser cancel
$SIG{PIPE} = 'IGNORE';
# Dirty pre-fork implementation
fork();fork();fork();

# Await requests and handle them as they arrive
while (my $client = $server->accept()) {
    $client->autoflush(1);
    my %request = ();
    my %data;
    {
#-------- Read Request ---------------

        local $/ = Socket::CRLF;
        while (<$client>) {
            chomp; # Main http request
            if (/\s*(\w+)\s*([^\s]+)\s*HTTP\/(\d.\d)/) {
                $request{METHOD} = uc $1;
                $request{URL} = $2;
                $request{HTTP_VERSION} = $3;
            } # Standard headers
            elsif (/:/) {
                (my $type, my $val) = split /:/, $_, 2;
                $type =~ s/^\s+//;
                foreach ($type, $val) {
                         s/^\s+//;
                         s/\s+$//;
                }
                $request{lc $type} = $val;
            } # POST data
            elsif (/^$/) {
                read($client, $request{CONTENT}, $request{'content-length'})
                    if defined $request{'content-length'};
                last;
            }
        }
    }
#-------- SORT OUT METHOD  ---------------
    if ($request{METHOD} eq 'GET') {
        if ($request{URL} =~ /(.*)\?(.*)/) {
                $request{URL} = $1;
                $request{CONTENT} = $2;
                %data = parse_form($request{CONTENT});
        } else {
                %data = ();
        }
        $cata{"_method"} = "GET";
    } elsif ($request{METHOD} eq 'POST') {
                %data = parse_form($request{CONTENT});
                $cata{"_method"} = "POST";
    } else {
        $cata{"_method"} = "ERROR";
    }
#------- Serve file ----------------------

$tamanho = length($request{URL});
$tamanho = $tamanho - 1;
$input = substr($request{URL},1,$tamanho);
$data{"_status"} = "200";

# ----------- Close Connection and loop ------------------
print $client "HTTP/1.0 200 OK", Socket::CRLF;
print $client "<center>", Socket::CRLF;
print $client "<!doctype html public -//w3c//dtd html 4.0 transitional//en>", Socket::CRLF;
print $client "<html>", Socket::CRLF;
print $client "<head>", Socket::CRLF;
print $client "<meta Content-type: text/html; charset=iso-8859-1>", Socket::CRLF;
print $client "<meta http-equiv=refresh content=5/>", Socket::CRLF;
print $client "</head>", Socket::CRLF;
print $client Socket::CRLF;
print $client "<title>Teste de pagina Web com perl</title>", Socket::CRLF;
print $client "<body leftmargin=0 rightmargin=0 bottommargin=0 topmargin=0>", Socket::CRLF;
print $client "
    <style>
      body {
      font-family: arial;
      font-size: 10px;

      }
      table {
      font-family: arial;
      font-size: 10px;
      }
    </style>";

print $client Socket::CRLF;
print $client "<center><h2>Teste de pagina web com perl</h2></center>", Socket::CRLF;
print $client "
        <center>
        <table border=1>
        <tr>
        <td  height=15 width=15 cellspan=1>
        <center><font face=Verdana color=black size=0>Servidor</font></center>
        </td>
        <td  height=15 width=15 cellspan=1>
        <center><font face=Verdana color=black size=0>Hora</font></center>
        </td>
        <td  height=15 width=15 cellspan=1>
        <center><font face=Verdana color=black size=0>Processo</font></center>
        </td>
        <td  height=15 width=15 cellspan=1>
        <center><font face=Verdana color=black size=0>Porta</font></center>
        </td>
        <td  height=15 width=15 cellspan=1>
        <center><font face=Verdana color=black size=0>Quantidade</font></center>
        </td>
        <td  height=15 width=15 cellspan=1>
        <center><font face=Verdana color=black size=0>Status</font></center>
        </td>
        </tr>";

        chdir($diri);
        opendir(DIR, $diri) || die "can't opendir $dirname: $!";
        @files = grep { !/^\./ } readdir(DIR);
        @files = sort { lc($a) cmp lc($b) } @files;
        $arquivos = scalar(@files);
        chdir($dirc);
        open(FILE,"process.Cfg");
        @activation = <FILE>;
        close (FILE);
        foreach $file (@files)
        {
                chdir($diri);
                open(FILE," $file");
                @dscp = <FILE>;
                close (FILE);
                foreach $arquivo (@dscp)
                {
                chomp($arquivo);
                ($host,$process,$port,$hour_system,$qt,$status) = split(/\|/,$arquivo);
                $line = "<td height=15 width=15 cellspan=1><center><font face=Verdana color=black size=0>$host</font></center></td><td height=15 width=15 cellspan=1><center><font face=Verdana color=black size=0>$hour_system</font></center></td><td height=15 width=15 cellspan=1><center><font face=Verdana color=black size=0>$process</font></center></td><td height=15 width=15 cellspan=1><center><font face=Verdana color=black size=0>$port</font></center></td><td height=15 width=15 cellspan=1><center><font face=Verdana color=black size=0>$qt</font></center></td><td height=15 width=15 cellspan=1><center><font face=Verdana color=black size=0>$status</font></center></td>";
                print $client "<tr>";
                print $client $line;
                }
        close $client;
        }

}
