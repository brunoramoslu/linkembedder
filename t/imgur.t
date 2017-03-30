use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my $embedder = LinkEmbedder->new;
my $link     = $embedder->get('http://imgur.com/2lXFJK0');
isa_ok($link, 'LinkEmbedder::Link::Imgur');
is_deeply $link->TO_JSON,
  {
  cache_age        => 0,
  height           => 0,
  html             => photo_html(),
  provider_name    => 'Imgur',
  provider_url     => 'http://imgur.com',
  thumbnail_height => 315,
  thumbnail_url    => 'http://i.imgur.com/2lXFJK0.png?fb',
  thumbnail_width  => 600,
  title            => 'Yay Mojo!',
  type             => 'photo',
  url              => 'https://i.imgur.com/2lXFJK0.png',
  version          => '1.0',
  width            => 0,
  },
  'json for imgur.com'
  or note $link->_dump;

done_testing;

sub photo_html {
  return <<'HERE';
<img src="https://i.imgur.com/2lXFJK0.png" alt="Yay Mojo!">
HERE
}
