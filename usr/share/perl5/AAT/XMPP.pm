=head1 NAME

AAT::XMPP - AAT XMPP module

(Extensible Messaging and Presence Protocol (Jabber))

Net::XMPP is buggy with OpenFire & TLS
-> comment 3 lines in Net::XMPP::Protocol (~line 1800) & disable TLS:

#if($self->{STREAM}->GetStreamFeature($self->GetStreamID(),"xmpp-sasl"))
#{
#    return $self->AuthSASL(%args);
#}

=cut
package AAT::XMPP;

use strict;
use Net::XMPP;

my %conf_file = ();

=head1 FUNCTIONS

=head2 Configuration($appli)

Returns the XMPP configuration

=cut
sub Configuration($)
{
	my $appli = shift;

	$conf_file{$appli} ||= AAT::Application::File($appli, "xmpp");
	my $conf = AAT::XML::Read($conf_file{$appli}, 1);

	return ($conf->{xmpp});
}

=head2 Connection_Test($appli)

Checks the XMPP Connection

=cut
sub Connection_Test($)
{
	my $appli = shift;
  my $status = 0;

	my $conf_xmpp = Configuration($appli);
	if (AAT::NOT_NULL($conf_xmpp->{server}))
	{
  	my $client = new Net::XMPP::Client();
  	my @res = $client->Connect(hostname => $conf_xmpp->{server}, 
			port => $conf_xmpp->{port}, tls => $conf_xmpp->{tls}, timeout => 3);
		if (@res)
		{
			my @res = $client->AuthSend(username => $conf_xmpp->{user}, 
				password => $conf_xmpp->{password}, resource => "resource" );
			$status = 1	
				if ((\@res == 0) || ((@res == 1 && $res[0]) || $res[0] eq 'ok'));
		}
	}

	return ($status);
}

=head2 Send_Message($appli, $msg, @dests)

Sends message '$msg' to '@dests' through XMPP

=cut
sub Send_Message($$@)
{
  my ($appli, $msg, @dests) = @_;

	my $conf_xmpp = Configuration($appli);
	my $client = new Net::XMPP::Client();
	my @res = $client->Connect(hostname => $conf_xmpp->{server}, 
		port => $conf_xmpp->{port}, tls => $conf_xmpp->{tls});
	if (@res)
	{
		$client->AuthSend('hostname' => $conf_xmpp->{server},
        'username' => $conf_xmpp->{user},
        'password' => $conf_xmpp->{password}, resource => 'resource' );
		foreach my $dest (@dests)
  	{
			$client->MessageSend('to' => $dest, 'body' => "$msg")
    		if (AAT::NOT_NULL($dest));
		}	
		sleep 1;
		$client->Disconnect();
	}
	else
  {
    AAT::Syslog("AAT::XMPP", "XMPP_INVALID_CONFIG");
  }
}

1;

=head1 AUTHOR

Sebastien Thebert <octo.devel@gmail.com>

=cut
