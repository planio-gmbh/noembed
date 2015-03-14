use lib '../lib';

use Plack::App::File;
use Plack::Builder;
use Plack::Util;
use Noembed;

my $noembed = Noembed->new;
my $cors = sub {
  my $app = shift;
  sub {
    my $env = shift;
    my $res = $app->($env);
    Plack::Util::response_cb($res, sub {
      my $res = shift;
      if (!Plack::Util::header_exists($res->[1], "Access-Control-Allow-Origin")) {
        Plack::Util::header_push($res->[1], "Access-Control-Allow-Origin", "*");
      }
      if (!Plack::Util::header_exists($res->[1], "Access-Control-Allow-Methods")) {
        Plack::Util::header_push($res->[1], "Access-Control-Allow-Methods", "GET");
      }
      if (!Plack::Util::header_exists($res->[1], "Access-Control-Allow-Headers")) {
        Plack::Util::header_push($res->[1], "Access-Control-Allow-Headers", "Origin, Accept, Content-Type");
      }
      return;
    });
  };
};

builder {
  enable ReverseProxy;

  mount "/" => sub {
    return [
             301,
             [
               'Content-Type' => 'text/plain',
               'Location' => 'https://plan.io/frequently-asked-questions/#item-280'
             ],
             ['redirecting']
           ]
  };

  mount "/noembed.css" => sub { $noembed->css_response };
  mount "/favicon/" => Plack::App::File->new(root => Noembed::share_dir . "/icons/")->to_app;
  mount "/javascripts/" => Plack::App::File->new(root => Noembed::share_dir . "/javascripts/")->to_app;

  mount "/providers" => builder {
    enable $cors;
    enable JSONP;
    sub { $noembed->providers_response };
  };

  mount "/embed" => builder {
    enable $cors;
    enable JSONP;
    $noembed->to_app;
  };
};
