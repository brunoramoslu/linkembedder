use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my $embedder = LinkEmbedder->new;

my $link = $embedder->get('http://paste.scsys.co.uk/557716');
isa_ok($link, 'LinkEmbedder::Link::Shadowcat');
cmp_deeply(
  $link->TO_JSON,
  {
    cache_age     => 0,
    html          => re(qr{<pre>&lt;too&gt;cool!&lt;/too&gt;</pre>}),
    provider_name => 'Shadowcat',
    provider_url  => 'http://shadow.cat/',
    title         => 'Paste 557716',
    type          => 'rich',
    url           => 'http://paste.scsys.co.uk/557716',
    version       => '1.0',
  },
  'http://paste.scsys.co.uk/557716',
) or note $link->_dump;

done_testing;
